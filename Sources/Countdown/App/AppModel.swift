import AppKit
import Observation

@MainActor @Observable
final class AppModel {
    let preferences: PreferencesStore
    let countdown: CountdownStore
    let skins: SkinStore
    let sound = CompletionSoundPlayer()
    var errorMessage: String?
    var importing = false
    var widgetVisible = true
    @ObservationIgnored private(set) var panelController: FloatingPanelController?
    @ObservationIgnored var openMainWindow: (() -> Void)?
    @ObservationIgnored private var importTask: Task<Void, Never>?

    init() throws {
        let directory = try FileManager.default.url(for: .applicationSupportDirectory,
            in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("local.countdown.app", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        preferences = PreferencesStore()
        countdown = CountdownStore(directory: directory)
        skins = try SkinStore(directory: directory)
        if !skins.skins.contains(where: { $0.id == preferences.selectedSkinID }),
           let previous = skins.skins.first(where: { $0.manifest.id == preferences.selectedSkinID }) {
            preferences.selectedSkinID = previous.id
        }
        countdown.onCompletion = { [weak self] in
            guard let self else { return }
            self.sound.play(skin: self.selectedSkin)
        }
    }

    var selectedSkin: Skin { skins.selected(id: preferences.selectedSkinID) }

    func showWidget() {
        if panelController == nil { panelController = FloatingPanelController(model: self) }
        widgetVisible = true
        panelController?.show()
    }

    func toggleWidget() {
        if widgetVisible && preferences.showMenuBarIcon {
            widgetVisible = false
            panelController?.hide()
        } else { showWidget() }
    }

    func primaryAction(expectedPhase: CountdownPhase) {
        countdown.refresh()
        guard countdown.phase == expectedPhase else { return }
        switch expectedPhase {
        case .idle:
            sound.stop()
            countdown.start(duration: preferences.duration)
        case .running, .paused:
            countdown.togglePause()
        case .completed:
            reset()
        }
    }

    func reset() {
        sound.stop()
        countdown.reset(duration: preferences.duration)
    }

    func select(_ skin: Skin) {
        sound.stop()
        preferences.selectedSkinID = skin.id
    }

    func delete(_ skin: Skin) {
        guard !skin.isBuiltIn else { return }
        do {
            let wasSelected = selectedSkin.id == skin.id
            try skins.delete(skin)
            if wasSelected {
                sound.stop()
                preferences.selectedSkinID = skins.skins[0].id
            }
        } catch { errorMessage = error.localizedDescription }
    }

    func menuBarVisibilityChanged() {
        if !preferences.showMenuBarIcon { showWidget() }
    }

    func chooseZIP() {
        guard !importing else { return }
        let picker = NSOpenPanel()
        picker.allowedContentTypes = [.zip]
        picker.allowsMultipleSelection = false
        picker.canChooseDirectories = false
        picker.begin { [weak self] result in
            guard result == .OK, let url = picker.url else { return }
            self?.importSkin(url)
        }
    }

    func importSkin(_ url: URL) {
        guard !importing else { return }
        importing = true
        importTask = Task {
            defer { importing = false; importTask = nil }
            do {
                let staged = try await SkinImporter.prepare(url: url, stagingParent: skins.library)
                defer { try? FileManager.default.removeItem(at: staged.deletingLastPathComponent()) }
                try Task.checkCancellation()
                preferences.selectedSkinID = try skins.install(staged: staged)
            } catch is CancellationError {
            } catch { errorMessage = error.localizedDescription }
        }
    }

    func cancelImport() { importTask?.cancel() }
}
