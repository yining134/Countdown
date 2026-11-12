import Foundation
import Observation

@MainActor @Observable
final class PreferencesStore {
    var durationMinutes: Int { didSet { defaults.set(durationMinutes, forKey: "minutes") } }
    var widgetSize: Double { didSet { defaults.set(widgetSize, forKey: "widgetSize") } }
    var showRemainingTime: Bool { didSet { defaults.set(showRemainingTime, forKey: "showRemainingTime") } }
    var showMenuBarIcon: Bool { didSet { defaults.set(showMenuBarIcon, forKey: "showMenuBarIcon") } }
    var selectedSkinID: String { didSet { defaults.set(selectedSkinID, forKey: "selectedSkinID") } }
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        let savedMinutes = UserDefaults.standard.integer(forKey: "minutes")
        durationMinutes = (1...1440).contains(savedMinutes) ? savedMinutes : 25
        let size = UserDefaults.standard.double(forKey: "widgetSize")
        widgetSize = (64...256).contains(size) ? size : 128
        showRemainingTime = UserDefaults.standard.bool(forKey: "showRemainingTime")
        showMenuBarIcon = UserDefaults.standard.object(forKey: "showMenuBarIcon") as? Bool ?? true
        selectedSkinID = UserDefaults.standard.string(forKey: "selectedSkinID") ?? "countdown.starter"
    }

    var duration: TimeInterval { Double(durationMinutes) * 60 }
}
