import SwiftUI

public extension Color {
    /// An sRGB color from a 24-bit hex literal, e.g. `Color(hex: 0xF2A953)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Hex values are the single source of truth for both the colors and the specimen catalog.
enum Hex {
    // Night: the atmosphere world
    static let midnight: UInt32 = 0x0A0F1E
    static let nightfall: UInt32 = 0x141B3A
    static let indigo: UInt32 = 0x2B2F6B
    static let cobalt: UInt32 = 0x4A5BD0
    static let deepForest: UInt32 = 0x0D2622
    static let pine: UInt32 = 0x1E463C
    static let moss: UInt32 = 0x5C7A3A
    static let snowBlue: UInt32 = 0x9DB8D6
    static let frost: UInt32 = 0xDCE7F2

    // Warmth: lamplight and hearth
    static let lamplight: UInt32 = 0xF2A953
    static let ochre: UInt32 = 0xC9973F
    static let ember: UInt32 = 0xE0663A
    static let vermilion: UInt32 = 0xC8432B
    static let sienna: UInt32 = 0x9A5A33
    static let umber: UInt32 = 0x4A2C1E
    static let dusk: UInt32 = 0x3A1E2E
    static let peach: UInt32 = 0xF2B79A

    // Light: beams, halos, signal
    static let magentaBeam: UInt32 = 0xFF4FA3
    static let cyanBeam: UInt32 = 0x4FE3F0
    static let periwinkle: UInt32 = 0xA9B4F2
    static let chartreuse: UInt32 = 0xF4F94B

    // Paper: the editorial world
    static let parchment: UInt32 = 0xF2EDE4
    static let vellum: UInt32 = 0xEADFD6
    static let inkBrown: UInt32 = 0x4E3020
    static let ink: UInt32 = 0x15110F
}

/// Raw palette. Each value traces back to a moodboard reference (see docs/02-design-system.md).
public enum CairPalette {
    public static let midnight = Color(hex: Hex.midnight)
    public static let nightfall = Color(hex: Hex.nightfall)
    public static let indigo = Color(hex: Hex.indigo)
    public static let cobalt = Color(hex: Hex.cobalt)
    public static let deepForest = Color(hex: Hex.deepForest)
    public static let pine = Color(hex: Hex.pine)
    public static let moss = Color(hex: Hex.moss)
    public static let snowBlue = Color(hex: Hex.snowBlue)
    public static let frost = Color(hex: Hex.frost)

    public static let lamplight = Color(hex: Hex.lamplight)
    public static let ochre = Color(hex: Hex.ochre)
    public static let ember = Color(hex: Hex.ember)
    public static let vermilion = Color(hex: Hex.vermilion)
    public static let sienna = Color(hex: Hex.sienna)
    public static let umber = Color(hex: Hex.umber)
    public static let dusk = Color(hex: Hex.dusk)
    public static let peach = Color(hex: Hex.peach)

    public static let magentaBeam = Color(hex: Hex.magentaBeam)
    public static let cyanBeam = Color(hex: Hex.cyanBeam)
    public static let periwinkle = Color(hex: Hex.periwinkle)
    public static let chartreuse = Color(hex: Hex.chartreuse)

    public static let parchment = Color(hex: Hex.parchment)
    public static let vellum = Color(hex: Hex.vellum)
    public static let inkBrown = Color(hex: Hex.inkBrown)
    public static let ink = Color(hex: Hex.ink)

    public static let catalog: [SwatchGroup] = [
        SwatchGroup(name: "Night", swatches: [
            Swatch(name: "Midnight", hex: Hex.midnight),
            Swatch(name: "Nightfall", hex: Hex.nightfall),
            Swatch(name: "Indigo", hex: Hex.indigo),
            Swatch(name: "Cobalt", hex: Hex.cobalt),
            Swatch(name: "Deep Forest", hex: Hex.deepForest),
            Swatch(name: "Pine", hex: Hex.pine),
            Swatch(name: "Moss", hex: Hex.moss),
            Swatch(name: "Snow Blue", hex: Hex.snowBlue),
            Swatch(name: "Frost", hex: Hex.frost),
        ]),
        SwatchGroup(name: "Warmth", swatches: [
            Swatch(name: "Lamplight", hex: Hex.lamplight),
            Swatch(name: "Ochre", hex: Hex.ochre),
            Swatch(name: "Ember", hex: Hex.ember),
            Swatch(name: "Vermilion", hex: Hex.vermilion),
            Swatch(name: "Sienna", hex: Hex.sienna),
            Swatch(name: "Umber", hex: Hex.umber),
            Swatch(name: "Dusk", hex: Hex.dusk),
            Swatch(name: "Peach", hex: Hex.peach),
        ]),
        SwatchGroup(name: "Light", swatches: [
            Swatch(name: "Magenta Beam", hex: Hex.magentaBeam),
            Swatch(name: "Cyan Beam", hex: Hex.cyanBeam),
            Swatch(name: "Periwinkle", hex: Hex.periwinkle),
            Swatch(name: "Chartreuse", hex: Hex.chartreuse),
        ]),
        SwatchGroup(name: "Paper", swatches: [
            Swatch(name: "Parchment", hex: Hex.parchment),
            Swatch(name: "Vellum", hex: Hex.vellum),
            Swatch(name: "Ink Brown", hex: Hex.inkBrown),
            Swatch(name: "Ink", hex: Hex.ink),
        ]),
    ]
}

/// Semantic roles. Views use these, not raw palette values, wherever a role exists.
public enum CairColor {
    public static let canvas = CairPalette.midnight
    public static let textPrimary = CairPalette.parchment
    public static let hairline = CairPalette.parchment.opacity(0.14)
    public static let gridLine = CairPalette.parchment.opacity(0.06)
    /// Opaque card fill used when Reduce Transparency is on.
    public static let surfaceSolid = Color(hex: 0x1A2035)
    /// The QUEST chartreuse. Reserved for rare, high-signal moments.
    public static let signal = CairPalette.chartreuse
    public static let paper = CairPalette.vellum
    public static let inkOnPaper = CairPalette.inkBrown
}

public struct Swatch: Identifiable, Sendable {
    public let name: String
    public let hex: UInt32
    public var id: String { name }
    public var color: Color { Color(hex: hex) }
    public var hexString: String { String(format: "#%06X", hex) }
}

public struct SwatchGroup: Identifiable, Sendable {
    public let name: String
    public let swatches: [Swatch]
    public var id: String { name }
}
