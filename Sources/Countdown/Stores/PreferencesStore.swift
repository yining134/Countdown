import Foundation
import Observation

@MainActor @Observable
final class PreferencesStore {
    var minutes: Int { didSet { defaults.set(minutes, forKey: "minutes") } }
    var widgetSize: Double { didSet { defaults.set(widgetSize, forKey: "widgetSize") } }
    var selectedSkinID: String { didSet { defaults.set(selectedSkinID, forKey: "selectedSkinID") } }
    @ObservationIgnored private let defaults = UserDefaults.standard

    init() {
        let savedMinutes = UserDefaults.standard.integer(forKey: "minutes")
        minutes = (1...1440).contains(savedMinutes) ? savedMinutes : 25
        let size = UserDefaults.standard.double(forKey: "widgetSize")
        widgetSize = (64...256).contains(size) ? size : 128
        selectedSkinID = UserDefaults.standard.string(forKey: "selectedSkinID") ?? "countdown.starter"
    }

    var duration: TimeInterval { Double(minutes) * 60 }
}
