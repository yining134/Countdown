import Foundation

enum AppResources {
    static let bundle: Bundle = {
        if let url = Bundle.main.resourceURL?.appendingPathComponent("Countdown_Countdown.bundle"),
            let packaged = Bundle(url: url)
        {
            return packaged
        }
        return Bundle.module
    }()
}
