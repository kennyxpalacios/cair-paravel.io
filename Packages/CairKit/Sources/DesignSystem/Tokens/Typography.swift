import SwiftUI

/// PostScript names of the bundled OFL faces. If a face fails to register,
/// `Font.custom` falls back to the system font, so the app never renders blank text.
public enum CairFontName {
    /// Bodoni Moda: high-contrast Didone (the FANTASY poster).
    public static let display = "BodoniModa-Regular"
    /// Instrument Serif: condensed editorial serif ("Where knowledge begins").
    public static let editorial = "InstrumentSerif-Regular"
    /// Instrument Serif Italic: Tumnus's voice.
    public static let editorialItalic = "InstrumentSerif-Italic"
    /// IBM Plex Mono: micro-data, coordinates, labels.
    public static let mono = "IBMPlexMono-Regular"
    public static let monoMedium = "IBMPlexMono-Medium"
}

/// The type hierarchy. Interactive controls and long body copy stay on SF Pro for
/// legibility and Dynamic Type; the custom faces carry the editorial moments.
public enum CairTextStyle: CaseIterable, Sendable {
    /// The countdown. Fixed size: it is the composition's anchor, not reading text.
    case heroNumerals
    /// Phase titles: "Expedition", "Tea Time".
    case displayTitle
    /// Editorial headlines in panels.
    case headline
    /// Tumnus's lines.
    case quote
    /// Reading copy.
    case body
    /// Buttons and pills.
    case control
    /// Tracked uppercase mono labels.
    case microLabel
    /// Coordinates, counters, small data.
    case microData
    /// Bold modern display for rare poster moments (the QUEST reference).
    case poster

    public func size(for layout: LayoutClass) -> CGFloat {
        let regular = layout == .regular
        switch self {
        case .heroNumerals: return regular ? 184 : 104
        case .displayTitle: return regular ? 58 : 38
        case .headline: return regular ? 34 : 27
        case .quote: return regular ? 28 : 22
        case .body: return 17
        case .control: return 16
        case .microLabel: return 11
        case .microData: return 12
        case .poster: return regular ? 72 : 44
        }
    }

    public func font(for layout: LayoutClass) -> Font {
        let size = size(for: layout)
        switch self {
        case .heroNumerals: return .custom(CairFontName.display, fixedSize: size)
        case .displayTitle: return .custom(CairFontName.display, size: size, relativeTo: .largeTitle)
        case .headline: return .custom(CairFontName.editorial, size: size, relativeTo: .title)
        case .quote: return .custom(CairFontName.editorialItalic, size: size, relativeTo: .title3)
        case .body: return .system(.body)
        case .control: return .system(.callout, weight: .semibold)
        case .microLabel: return .custom(CairFontName.monoMedium, size: size, relativeTo: .caption2)
        case .microData: return .custom(CairFontName.mono, size: size, relativeTo: .caption)
        case .poster: return .system(size: size, weight: .black).width(.expanded)
        }
    }

    public var tracking: CGFloat {
        switch self {
        case .microLabel: 1.8
        case .microData: 0.6
        case .displayTitle: 0.4
        case .poster: -1
        default: 0
        }
    }

    public var textCase: Text.Case? {
        self == .microLabel ? .uppercase : nil
    }

    /// Human-readable spec line for the design specimen.
    public func specLabel(for layout: LayoutClass) -> String {
        let face: String = switch self {
        case .heroNumerals, .displayTitle: "Bodoni Moda"
        case .headline: "Instrument Serif"
        case .quote: "Instrument Serif Italic"
        case .body, .control: "SF Pro"
        case .microLabel, .microData: "IBM Plex Mono"
        case .poster: "SF Pro Expanded Black"
        }
        return "\(self) · \(face) · \(Int(size(for: layout))) pt"
    }
}

private struct CairTextModifier: ViewModifier {
    let style: CairTextStyle
    @Environment(\.cairLayout) private var layout

    func body(content: Content) -> some View {
        content
            .font(style.font(for: layout))
            .tracking(style.tracking)
            .textCase(style.textCase)
    }
}

public extension View {
    /// Applies a Cair text style, sized for the current layout class.
    func cairText(_ style: CairTextStyle) -> some View {
        modifier(CairTextModifier(style: style))
    }
}
