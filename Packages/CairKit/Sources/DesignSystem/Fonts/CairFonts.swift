import CoreText
import Foundation

/// Registers fonts at runtime. Package resources cannot use `UIAppFonts`, so the
/// bundled OFL faces are registered with Core Text when the app launches.
public enum CairFonts {
    @MainActor private static var didRegisterBundledFonts = false

    /// Registers the faces that ship inside DesignSystem. Safe to call more than once.
    @MainActor public static func registerBundledFonts() {
        guard !didRegisterBundledFonts else { return }
        didRegisterBundledFonts = true
        register(in: .module)
    }

    /// Registers every .ttf and .otf in `bundle`. The app calls this on its main bundle
    /// so fonts dropped into the gitignored App/Resources/Fonts/Local folder load too.
    @MainActor public static func register(in bundle: Bundle) {
        var urls = Set<URL>()
        for ext in ["ttf", "otf"] {
            for subdirectory in [nil, "Fonts"] as [String?] {
                urls.formUnion(bundle.urls(forResourcesWithExtension: ext, subdirectory: subdirectory) ?? [])
            }
        }
        for url in urls {
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
