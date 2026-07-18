import Foundation
import CoreText
import OSLog

class RadicalFontManager {
    static let shared = RadicalFontManager()
    static let fontName = "黑体字根"

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "WubiTypingTrainer", category: "RadicalFontManager")

    private var fontAvailable = false

    private init() {
        registerFont()
    }

    private func registerFont() {
        let fontURL = Bundle.main.url(forResource: Self.fontName, withExtension: "ttf")
            ?? Bundle.main.url(forResource: Self.fontName, withExtension: "ttf", subdirectory: "font")
        guard let fontURL else {
            logger.error("Font file not found in bundle")
            return
        }

        let registered = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        if registered {
            fontAvailable = true
            logger.notice("Font registered: \(Self.fontName)")
            return
        }

        let font = CTFontCreateWithName(Self.fontName as CFString, 12, nil)
        fontAvailable = (CTFontCopyFamilyName(font) as String) == Self.fontName
        if fontAvailable {
            logger.info("Font already available: \(Self.fontName)")
        } else {
            logger.error("Font registration failed")
        }
    }

    var isFontAvailable: Bool {
        fontAvailable
    }
}
