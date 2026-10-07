import SwiftUI

/// The three material worlds of Cair Paravel.
public enum SurfaceStyle: Sendable {
    /// Liquid Glass. Interactive controls: pills, docks, buttons.
    case glass
    /// Custom frosted card: material, mood tint, grain, rim highlight. Large floating panels.
    case frost
    /// Editorial paper: vellum, grain, ink hairline. The Chronicles.
    case paper
}

public extension View {
    /// Places the view on a Cair surface clipped to `shape`.
    func cairSurface<S: InsettableShape>(_ style: SurfaceStyle, in shape: S, tint: Color? = nil) -> some View {
        modifier(SurfaceModifier(style: style, shape: shape, tint: tint))
    }
}

private struct SurfaceModifier<S: InsettableShape>: ViewModifier {
    let style: SurfaceStyle
    let shape: S
    let tint: Color?

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.cairMood) private var mood

    private var resolvedTint: Color { tint ?? mood.palette.glassTint }

    @ViewBuilder
    func body(content: Content) -> some View {
        switch style {
        case .glass:
            if reduceTransparency {
                solid(content)
            } else {
                content.glassEffect(.regular.tint(resolvedTint.opacity(0.18)), in: shape)
            }
        case .frost:
            if reduceTransparency {
                solid(content)
            } else {
                content
                    .background {
                        ZStack {
                            shape.fill(.ultraThinMaterial)
                            shape.fill(
                                LinearGradient(
                                    colors: [resolvedTint.opacity(0.18), resolvedTint.opacity(0.04)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            GrainOverlay(opacity: 0.06).clipShape(shape)
                        }
                    }
                    .overlay {
                        shape.strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.32), .white.opacity(0.04), .white.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: CairStroke.rule
                        )
                    }
                    .shadow(color: .black.opacity(0.35), radius: 30, y: 18)
            }
        case .paper:
            content
                .background {
                    ZStack {
                        shape.fill(CairColor.paper)
                        GrainOverlay(opacity: 0.14).clipShape(shape)
                    }
                }
                .overlay {
                    shape.strokeBorder(CairColor.inkOnPaper.opacity(0.35), lineWidth: CairStroke.rule)
                }
        }
    }

    private func solid(_ content: Content) -> some View {
        content
            .background(CairColor.surfaceSolid, in: shape)
            .overlay {
                shape.strokeBorder(CairColor.hairline, lineWidth: CairStroke.rule)
            }
    }
}
