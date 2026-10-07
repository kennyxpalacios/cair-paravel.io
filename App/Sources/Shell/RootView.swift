import DesignSystem
import SwiftUI

/// Picks the layout family from available width and paints the shared canvas layers.
struct RootView: View {
    @State private var model = ShellModel()
    @State private var width: CGFloat = 1024

    var body: some View {
        let layout = LayoutClass(width: width)
        ZStack {
            MoodBackdrop(mood: model.mood)
            GrainOverlay()
                .ignoresSafeArea()
            if model.showsGrid {
                EditorialGridOverlay()
                    .ignoresSafeArea()
            }
            switch layout {
            case .regular: RegularShell(model: model, width: width)
            case .compact: CompactShell(model: model)
            }
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { newWidth in
            width = newWidth
        }
        .environment(\.cairLayout, layout)
        .environment(\.cairMood, model.mood)
        .foregroundStyle(CairColor.textPrimary)
        .tint(model.mood.palette.accent)
        .sensoryFeedback(.impact(weight: .light, intensity: 0.6), trigger: model.isRunning)
        .sensoryFeedback(.selection, trigger: model.mood)
        .sheet(isPresented: $model.showsWorkshop) {
            #if DEBUG
            WorkshopSheet(model: model)
            #endif
        }
    }
}

#Preview("iPad") {
    RootView()
}
