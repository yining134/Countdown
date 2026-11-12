import Foundation

enum L10n {
    static func text(_ key: String) -> String {
        Bundle.module.localizedString(forKey: key, value: nil, table: nil)
    }

    static func format(_ key: String, _ value: String) -> String {
        String(format: text(key), locale: Locale.current, value)
    }
}
