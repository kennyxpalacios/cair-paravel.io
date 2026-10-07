import SwiftUI

/// Full-bleed canvas for a mood: a slowly breathing mesh gradient that crossfades
/// between moods. This is atmosphere tier 0; Phase 4 layers beams, dust, and light on top.
public struct MoodBackdrop: View {
    private let mood: AtmosphereMood

    public init(mood: AtmosphereMood) {
        self.mood = mood
    }

    public var body: some View {
        ZStack {
            MoodField(mood: mood)
                .id(mood)
                .transition(.opacity)
        }
        .animation(CairMotion.moodShift, value: mood)
        .background(CairColor.canvas)
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// The mesh field on its own, for tiles and previews.
public struct MoodField: View {
    private let mood: AtmosphereMood
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(mood: AtmosphereMood) {
        self.mood = mood
    }

    public var body: some View {
        let colors = mood.palette.mesh
        let animated = !reduceMotion
        TimelineView(.animation(minimumInterval: CairMotion.ambientFrameInterval, paused: !animated)) { context in
            MeshGradient(
                width: 3,
                height: 3,
                points: Self.points(at: context.date, animated: animated),
                colors: colors
            )
        }
    }

    /// Corners stay pinned; edge midpoints slide along their edge and the center drifts,
    /// so the field breathes without ever exposing a gap.
    static func points(at date: Date, animated: Bool) -> [SIMD2<Float>] {
        let a: Float = animated ? Float(CairMotion.breath(at: date, period: CairMotion.driftPeriod) - 0.5) : 0
        let b: Float = animated ? Float(CairMotion.breath(at: date, period: CairMotion.breathPeriod * 1.3) - 0.5) : 0
        return [
            SIMD2(0, 0), SIMD2(0.5 + 0.08 * a, 0), SIMD2(1, 0),
            SIMD2(0, 0.5 + 0.06 * b), SIMD2(0.5 + 0.07 * b, 0.5 + 0.06 * a), SIMD2(1, 0.5 - 0.06 * b),
            SIMD2(0, 1), SIMD2(0.5 - 0.08 * a, 1), SIMD2(1, 1),
        ]
    }
}
