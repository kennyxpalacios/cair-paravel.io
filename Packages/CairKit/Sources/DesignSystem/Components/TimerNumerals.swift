import SwiftUI

/// The hero countdown in Bodoni Moda. Every glyph sits in a fixed-width slot, so the
/// digits never shift sideways as they tick (Bodoni's figures are proportional).
public struct TimerNumerals: View {
    private let seconds: Int

    @Environment(\.cairLayout) private var layout

    public init(seconds: Int) {
        self.seconds = max(0, seconds)
    }

    public var body: some View {
        let size = CairTextStyle.heroNumerals.size(for: layout)
        let font = CairTextStyle.heroNumerals.font(for: layout)
        let glyphs = Array(Self.format(seconds))
        HStack(spacing: 0) {
            ForEach(glyphs.indices, id: \.self) { index in
                let glyph = glyphs[index]
                Text(String(glyph))
                    .font(font)
                    .frame(width: glyph == ":" ? size * 0.3 : size * 0.58)
                    .contentTransition(.numericText(countsDown: true))
            }
        }
        .animation(CairMotion.numerals, value: seconds)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.spokenLabel(seconds))
    }

    /// "mm:ss" with zero padding.
    public static func format(_ seconds: Int) -> String {
        let clamped = max(0, seconds)
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    static func spokenLabel(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainder = seconds % 60
        return "\(minutes) minutes, \(remainder) seconds"
    }
}
