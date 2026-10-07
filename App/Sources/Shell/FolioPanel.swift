import DesignSystem
import SwiftUI

/// The iPad side panel: a frosted folio that switches between The Chronicles and the Media Hub.
struct FolioPanel: View {
    @Bindable var model: ShellModel
    let panel: Panel

    var body: some View {
        VStack(alignment: .leading, spacing: CairSpace.l) {
            HStack(spacing: CairSpace.s) {
                Picker("Panel", selection: $model.panel) {
                    ForEach(Panel.allCases) { option in
                        Text(option.title).tag(Optional(option))
                    }
                }
                .pickerStyle(.segmented)

                HUDIconButton(symbol: "xmark", label: "Close", isActive: false) {
                    model.panel = nil
                }
            }

            ScrollView {
                PanelContent(panel: panel)
            }
            .scrollIndicators(.hidden)
        }
        .padding(CairSpace.l)
        .frame(maxHeight: .infinity, alignment: .top)
        .cairSurface(.frost, in: .rect(cornerRadius: CairRadius.panel))
    }
}

/// Shared panel content for the iPad folio and the iPhone sheets.
struct PanelContent: View {
    let panel: Panel

    var body: some View {
        switch panel {
        case .chronicles: ChroniclesPreview()
        case .mediaHub: MediaHubPreview()
        }
    }
}
