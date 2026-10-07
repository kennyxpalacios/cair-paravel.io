#if DEBUG
import DesignSystem
import SwiftUI

/// Debug-only review controls: flip moods and states, toggle the grid, open the specimen.
struct WorkshopSheet: View {
    @Bindable var model: ShellModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Mood", selection: $model.mood) {
                        ForEach(AtmosphereMood.allCases) { mood in
                            Text(mood.title).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)
                    Toggle("Session running", isOn: $model.isRunning)
                    Toggle("Editorial grid", isOn: $model.showsGrid)
                } header: {
                    Text("Preview state")
                } footer: {
                    Text("Phase 2 review controls. The real timer engine arrives in Phase 3.")
                }

                Section {
                    NavigationLink("Design specimen") {
                        DesignSpecimenView(mood: model.mood)
                    }
                }
            }
            .navigationTitle("Workshop")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
#endif
