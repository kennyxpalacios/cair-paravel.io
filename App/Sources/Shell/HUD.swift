import DesignSystem
import SwiftUI

/// The glass control dock. On compact layouts it also carries the panel buttons.
struct ControlDock: View {
    @Bindable var model: ShellModel
    @Environment(\.cairLayout) private var layout

    var body: some View {
        GlassEffectContainer(spacing: CairSpace.m) {
            HStack(spacing: CairSpace.s) {
                if model.mood != .lamplight {
                    HUDIconButton(symbol: "stop.fill", label: "End", isActive: false) {
                        model.end()
                    }
                }

                Button {
                    model.primaryAction()
                } label: {
                    Label(
                        model.mood.primaryLabel(isRunning: model.isRunning),
                        systemImage: model.mood.primarySymbol(isRunning: model.isRunning)
                    )
                    .cairText(.control)
                    .contentTransition(.interpolate)
                    .padding(.horizontal, CairSpace.s)
                    .frame(minHeight: CairSize.minTouch)
                }
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .keyboardShortcut(.space, modifiers: [])

                if model.mood == .expedition {
                    HUDIconButton(symbol: "cup.and.saucer.fill", label: "Skip to Tea Time", isActive: false) {
                        model.skipToTeaTime()
                    }
                }

                if layout == .compact {
                    ForEach(Panel.allCases) { panel in
                        HUDIconButton(symbol: panel.symbol, label: panel.title, isActive: model.panel == panel) {
                            model.toggle(panel)
                        }
                    }
                }
            }
        }
        .animation(CairMotion.settle, value: model.mood)
        .animation(CairMotion.settle, value: model.isRunning)
    }
}

/// Panel toggles (and the debug workshop) for the regular top bar.
struct HUDButtonCluster: View {
    @Bindable var model: ShellModel

    var body: some View {
        GlassEffectContainer(spacing: CairSpace.s) {
            HStack(spacing: CairSpace.s) {
                ForEach(Panel.allCases) { panel in
                    HUDIconButton(symbol: panel.symbol, label: panel.title, isActive: model.panel == panel) {
                        model.toggle(panel)
                    }
                    .keyboardShortcut(panel == .chronicles ? "1" : "2", modifiers: .command)
                }
                #if DEBUG
                HUDIconButton(symbol: "wrench.and.screwdriver", label: "Workshop", isActive: false) {
                    model.showsWorkshop = true
                }
                #endif
            }
        }
    }
}

/// A round glass icon button. Active state uses the prominent (tinted) glass.
struct HUDIconButton: View {
    let symbol: String
    let label: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        let button = Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .frame(width: 24, height: 24)
        }
        .buttonBorderShape(.circle)
        .controlSize(.large)
        .accessibilityLabel(label)

        if isActive {
            button.buttonStyle(.glassProminent)
        } else {
            button.buttonStyle(.glass)
        }
    }
}
