import DesignSystem
import SwiftUI

@main
struct CairParavelApp: App {
    init() {
        CairFonts.registerBundledFonts()
        CairFonts.register(in: .main)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
