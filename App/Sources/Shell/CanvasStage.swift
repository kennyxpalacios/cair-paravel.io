import DesignSystem
import SwiftUI

/// The focal composition: Tumnus, the phase title, the countdown, and his line.
struct CanvasStage: View {
    @Bindable var model: ShellModel
    @Environment(\.cairLayout) private var layout

    private var companionSize: CGFloat { layout == .regular ? 300 : 180 }

    var body: some View {
        VStack(spacing: layout == .regular ? CairSpace.m : CairSpace.s) {
            CompanionPlaceholder()
                .frame(width: companionSize, height: companionSize)

            Text(model.mood.title)
                .cairText(.displayTitle)
                .contentTransition(.interpolate)

            TimerNumerals(seconds: model.previewSeconds)
                .padding(.horizontal, CairSpace.l)
                .padding(.vertical, CairSpace.xs)
                .overlay {
                    CornerBrackets(length: layout == .regular ? 20 : 14)
                        .stroke(.tertiary, lineWidth: CairStroke.rule)
                }

            Text(model.mood.companionLine)
                .cairText(.quote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .contentTransition(.interpolate)
                .padding(.top, CairSpace.xs)
        }
        .padding(.horizontal, CairSpace.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(CairMotion.settle, value: model.mood)
    }
}
