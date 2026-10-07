import DesignSystem
import SwiftUI

/// Stands in for Tumnus until the rig lands in Phase 4: his aura breathing around the
/// lamppost where he waits. Sized by the parent frame.
struct CompanionPlaceholder: View {
    @Environment(\.cairMood) private var mood
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let aura = mood.palette.aura
            TimelineView(.animation(minimumInterval: CairMotion.ambientFrameInterval, paused: reduceMotion)) { context in
                let breath = reduceMotion ? 0.5 : CairMotion.breath(at: context.date)
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [aura.opacity(0.5), aura.opacity(0.12), aura.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: side / 2
                            )
                        )
                        .scaleEffect(0.84 + 0.16 * breath)

                    LamppostGlyph()
                        .stroke(.secondary, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                        .frame(width: side * 0.24, height: side * 0.56)

                    Circle()
                        .fill(CairPalette.lamplight)
                        .frame(width: side * 0.035, height: side * 0.035)
                        .shadow(color: CairPalette.lamplight, radius: side * 0.04)
                        .offset(y: -side * 0.56 * (0.5 - LamppostGlyph.lanternCenter))
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
            }
        }
        .overlay(alignment: .bottom) {
            MicroLabel("\(Brand.companionName) · art in progress")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(Brand.companionName), your companion. His artwork arrives in a later phase.")
    }
}

/// A line-drawn lamppost: post, base, crossbar, lantern, and cap. `nonisolated` because the
/// app target is MainActor by default and `Shape` must be usable off the main actor.
nonisolated struct LamppostGlyph: Shape {
    /// Lantern center as a fraction of height from the top.
    static let lanternCenter: CGFloat = 0.19

    func path(in rect: CGRect) -> Path {
        let cx = rect.midX
        let w = rect.width
        let h = rect.height
        let lanternTop = rect.minY + h * 0.08
        let lanternBottom = rect.minY + h * 0.30
        var path = Path()
        // Post and base
        path.move(to: CGPoint(x: cx, y: rect.maxY))
        path.addLine(to: CGPoint(x: cx, y: lanternBottom))
        path.move(to: CGPoint(x: cx - w * 0.3, y: rect.maxY))
        path.addLine(to: CGPoint(x: cx + w * 0.3, y: rect.maxY))
        // Crossbar
        path.move(to: CGPoint(x: cx - w * 0.42, y: rect.minY + h * 0.36))
        path.addLine(to: CGPoint(x: cx + w * 0.42, y: rect.minY + h * 0.36))
        // Lantern
        path.move(to: CGPoint(x: cx - w * 0.26, y: lanternTop))
        path.addLine(to: CGPoint(x: cx + w * 0.26, y: lanternTop))
        path.addLine(to: CGPoint(x: cx + w * 0.18, y: lanternBottom))
        path.addLine(to: CGPoint(x: cx - w * 0.18, y: lanternBottom))
        path.closeSubpath()
        // Cap and finial
        path.move(to: CGPoint(x: cx - w * 0.36, y: lanternTop))
        path.addLine(to: CGPoint(x: cx, y: rect.minY + h * 0.02))
        path.addLine(to: CGPoint(x: cx + w * 0.36, y: lanternTop))
        path.move(to: CGPoint(x: cx, y: rect.minY + h * 0.02))
        path.addLine(to: CGPoint(x: cx, y: rect.minY))
        return path
    }
}
