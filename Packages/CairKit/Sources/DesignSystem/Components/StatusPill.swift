import SwiftUI

/// The phase status pill (from the glass pill over the painted landscape): a glass capsule
/// whose copy morphs as the session changes state.
public struct StatusPill: View {
    private let title: String
    private let detail: String?
    private let isLive: Bool

    @Environment(\.cairMood) private var mood

    public init(_ title: String, detail: String? = nil, isLive: Bool = false) {
        self.title = title
        self.detail = detail
        self.isLive = isLive
    }

    public var body: some View {
        HStack(spacing: CairSpace.s) {
            LiveDot(color: isLive ? mood.palette.accent : CairPalette.parchment.opacity(0.4), isLive: isLive)
            Text(title)
                .cairText(.control)
                .contentTransition(.interpolate)
            if let detail {
                Text(detail)
                    .cairText(.microData)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, CairSpace.m + CairSpace.xxs)
        .padding(.vertical, CairSpace.s)
        .cairSurface(.glass, in: Capsule())
        .animation(CairMotion.pill, value: title)
        .animation(CairMotion.pill, value: isLive)
        .accessibilityElement(children: .combine)
    }
}

/// A dot that breathes slowly while a session is live. Still under Reduce Motion.
private struct LiveDot: View {
    let color: Color
    let isLive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let pulsing = isLive && !reduceMotion
        TimelineView(.animation(minimumInterval: CairMotion.ambientFrameInterval, paused: !pulsing)) { context in
            let phase = pulsing ? CairMotion.breath(at: context.date, period: 4) : 0
            ZStack {
                Circle()
                    .fill(color.opacity(0.3 * (1 - phase)))
                    .frame(width: 8 + 10 * phase, height: 8 + 10 * phase)
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
            }
        }
        .frame(width: 18, height: 18)
        .accessibilityHidden(true)
    }
}
