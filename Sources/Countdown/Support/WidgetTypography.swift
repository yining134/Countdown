import CoreText
import SwiftUI

enum WidgetTypography {
    static let countdown: Font = {
        guard
            let url = AppResources.bundle.url(
                forResource: "VT323-Regular", withExtension: "ttf", subdirectory: "Fonts"),
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        else {
            return .system(size: 12, weight: .medium, design: .rounded).monospacedDigit()
        }
        return .custom("VT323", fixedSize: 20)
    }()
}
