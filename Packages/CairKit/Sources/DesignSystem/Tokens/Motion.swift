import SwiftUI

/// Motion tokens. The low-stimulation contract: ambient loops are slow (8 to 14 s),
/// render at 30 fps, never flash, and freeze entirely under Reduce Motion.
public enum CairMotion {
    /// One full breath of the aura and live indicators.
    public static let breathPeriod: Double = 10
    /// The slower drift of the mesh field.
    public static let driftPeriod: Double = 14
    /// Frame interval for every ambient TimelineView.
    public static let ambientFrameInterval: Double = 1.0 / 30.0

    public static var settle: Animation { .smooth(duration: 0.6) }
    public static var panel: Animation { .spring(duration: 0.5, bounce: 0.12) }
    public static var pill: Animation { .smooth(duration: 0.45) }
    public static var moodShift: Animation { .easeInOut(duration: 1.6) }
    public static var numerals: Animation { .smooth(duration: 0.35) }

    /// A 0...1 sine phase for slow ambient loops.
    public static func breath(at date: Date, period: Double = breathPeriod) -> Double {
        let t = date.timeIntervalSinceReferenceDate
        return 0.5 + 0.5 * sin(2 * .pi * t / period)
    }
}
