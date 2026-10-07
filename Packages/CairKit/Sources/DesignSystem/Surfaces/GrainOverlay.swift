import SwiftUI

/// Paper and film grain: a tiled noise texture blended in overlay mode.
/// Static by design. Grain that crawls is a stimulation source.
public struct GrainOverlay: View {
    private let opacity: Double

    public init(opacity: Double = 0.07) {
        self.opacity = opacity
    }

    public var body: some View {
        Image("Grain", bundle: .module)
            .resizable(resizingMode: .tile)
            .opacity(opacity)
            .blendMode(.overlay)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}
