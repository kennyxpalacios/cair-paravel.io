import DesignSystem
import SwiftUI

/// iPhone, and iPad windows narrower than 700 pt. One focal column: status, stage,
/// dock. The folio panels arrive as sheets.
struct CompactShell: View {
    @Bindable var model: ShellModel

    private var margin: CGFloat { EditorialGrid.standard(for: .compact).margin }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                StatusPill(
                    model.mood.statusTitle(isRunning: model.isRunning),
                    detail: model.mood.statusDetail,
                    isLive: model.isRunning
                )
                #if DEBUG
                HStack {
                    Spacer()
                    HUDIconButton(symbol: "wrench.and.screwdriver", label: "Workshop", isActive: false) {
                        model.showsWorkshop = true
                    }
                }
                #endif
            }
            .padding(.horizontal, margin)
            .padding(.top, CairSpace.xs)

            CanvasStage(model: model)

            ControlDock(model: model)
                .padding(.horizontal, margin)
                .padding(.bottom, CairSpace.s)
        }
        .sheet(item: $model.panel) { panel in
            ScrollView {
                PanelContent(panel: panel)
                    .padding(margin)
            }
            .scrollIndicators(.hidden)
            .presentationDetents([.medium, .large])
            .presentationBackground(.ultraThinMaterial)
            .presentationCornerRadius(CairRadius.panel)
        }
    }
}
