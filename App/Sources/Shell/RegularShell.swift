import DesignSystem
import SwiftUI

/// iPad full screen and wide windows: the design lead. A full-bleed canvas with a
/// floating HUD. The folio panel docks beside the canvas on wide screens and floats
/// over it on narrower ones (portrait iPad).
struct RegularShell: View {
    @Bindable var model: ShellModel
    let width: CGFloat

    private var docksPanel: Bool { width >= LayoutClass.dockedPanelMinWidth }
    private var margin: CGFloat { EditorialGrid.standard(for: .regular).margin }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                CanvasStage(model: model)
                VStack(spacing: 0) {
                    RegularTopBar(model: model)
                    Spacer(minLength: CairSpace.l)
                    ControlDock(model: model)
                }
                .padding(.horizontal, margin)
                .padding(.vertical, CairSpace.l)
            }
            if docksPanel, let panel = model.panel {
                FolioPanel(model: model, panel: panel)
                    .frame(width: CairSize.panelWidth)
                    .padding([.top, .bottom, .trailing], CairSpace.l)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .overlay(alignment: .trailing) {
            if !docksPanel, let panel = model.panel {
                FolioPanel(model: model, panel: panel)
                    .frame(width: CairSize.panelWidth)
                    .padding(CairSpace.l)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(CairMotion.panel, value: model.panel)
    }
}

private struct RegularTopBar: View {
    @Bindable var model: ShellModel

    var body: some View {
        HStack(alignment: .top, spacing: CairSpace.l) {
            MicroDataStack(PlaceData.lines(for: .now))
                .frame(maxWidth: .infinity, alignment: .leading)
            StatusPill(
                model.mood.statusTitle(isRunning: model.isRunning),
                detail: model.mood.statusDetail,
                isLive: model.isRunning
            )
            HUDButtonCluster(model: model)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}
