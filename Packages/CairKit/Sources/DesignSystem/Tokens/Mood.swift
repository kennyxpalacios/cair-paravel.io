import SwiftUI

/// The atmospheric state the whole canvas is tuned to. The timer engine (Phase 3)
/// decides the mood; everything visual reads it from the environment.
public enum AtmosphereMood: String, CaseIterable, Identifiable, Sendable {
    /// Waiting under the lamppost: no session running.
    case lamplight
    /// Focus: cool forest depth with a neon rim.
    case expedition
    /// Rest: hearth amber and dusk.
    case teaTime

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .lamplight: "Lamplight"
        case .expedition: "Expedition"
        case .teaTime: "Tea Time"
        }
    }

    public var palette: MoodPalette {
        switch self {
        case .lamplight: .lamplight
        case .expedition: .expedition
        case .teaTime: .teaTime
        }
    }
}

public struct MoodPalette: Sendable {
    /// 3 × 3 mesh colors, row-major, top-left to bottom-right.
    public let mesh: [Color]
    /// Live indicators, prominent buttons, focus rings.
    public let accent: Color
    /// Tint mixed into glass surfaces.
    public let glassTint: Color
    /// Tumnus's aura.
    public let aura: Color
    /// Neon rim light on edges and silhouettes.
    public let rim: Color

    /// Snow-blue night with an amber pool of lamplight at the center.
    static let lamplight = MoodPalette(
        mesh: [
            Color(hex: 0x080C1A), Color(hex: 0x121838), Color(hex: 0x080C1A),
            Color(hex: 0x1C2150), Color(hex: 0x7A5230), Color(hex: 0x1C2150),
            Color(hex: 0x26344F), Color(hex: 0x5F7699), Color(hex: 0x26344F),
        ],
        accent: CairPalette.lamplight,
        glassTint: CairPalette.lamplight,
        aura: CairPalette.lamplight,
        rim: CairPalette.periwinkle
    )

    /// Deep forest under a cobalt canopy, a magenta beam bleeding in from the upper left.
    static let expedition = MoodPalette(
        mesh: [
            Color(hex: 0x2C1F5E), Color(hex: 0x16204A), Color(hex: 0x0B1430),
            Color(hex: 0x10303A), Color(hex: 0x0D2622), Color(hex: 0x12332E),
            Color(hex: 0x07120F), Color(hex: 0x0C1E19), Color(hex: 0x050B0A),
        ],
        accent: CairPalette.cyanBeam,
        glassTint: CairPalette.cyanBeam,
        aura: CairPalette.cyanBeam,
        rim: CairPalette.magentaBeam
    )

    /// Dusk plum above a hearth glow.
    static let teaTime = MoodPalette(
        mesh: [
            Color(hex: 0x1E1020), Color(hex: 0x3A1E2E), Color(hex: 0x1E1020),
            Color(hex: 0x4A2C1E), Color(hex: 0x9A5A33), Color(hex: 0x4A2C1E),
            Color(hex: 0x2A160F), Color(hex: 0xB86F3E), Color(hex: 0x2A160F),
        ],
        accent: CairPalette.peach,
        glassTint: CairPalette.ember,
        aura: CairPalette.peach,
        rim: CairPalette.lamplight
    )
}
