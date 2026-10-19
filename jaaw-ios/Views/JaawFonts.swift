import CoreText
import SwiftUI
import UIKit

// MARK: - Bundled fonts
// Caveat, the handwriting face behind the holiday / empty-state scribbles
// (`nothing on today, enjoy!`). iOS has no equivalent system face, so the
// static Semibold instance is bundled and registered with CoreText at launch
// (the project generates its Info.plist, so `UIAppFonts` isn't an option).

enum JaawFonts {
    /// PostScript name of the bundled Caveat instance.
    static let caveat = "Caveat-SemiBold"

    /// Registers every bundled `.ttf`/`.otf` with CoreText. Call once at launch.
    static func registerBundledFonts() {
        for url in bundledFontURLs() {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    /// Caveat, used for the holiday and empty-state scribbles.
    ///
    /// Caveat bundles contextual alternates (`calt`) that swap in "connect"
    /// forms for letters such as `y`, `d`, `a` and `i`. CoreText still applies
    /// them when the glyph ends a word, where the alternate's sliced entry
    /// stroke reads as a clipped letter — most visibly the `y` in "Holiday".
    /// Disabling `calt` keeps the clean, self-contained letterforms.
    static func script(_ size: CGFloat) -> Font {
        Font(scriptFont(size))
    }

    private static func scriptFont(_ size: CGFloat) -> UIFont {
        guard let base = UIFont(name: caveat, size: size) else {
            return .systemFont(ofSize: size, weight: .semibold)
        }
        let features: [[CFString: Any]] = [[
            kCTFontOpenTypeFeatureTag: "calt" as CFString,
            kCTFontOpenTypeFeatureValue: 0
        ]]
        let descriptor = base.fontDescriptor.addingAttributes([.featureSettings: features])
        return UIFont(descriptor: descriptor, size: size)
    }

    /// True once Caveat is available, so callers can fall back gracefully.
    static var hasScript: Bool {
        UIFont(name: caveat, size: 12) != nil
    }

    private static func bundledFontURLs() -> [URL] {
        let extensions = ["ttf", "otf"]
        var urls: [URL] = []
        for ext in extensions {
            let found = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) ?? []
            urls.append(contentsOf: found)
        }
        return urls
    }
}
