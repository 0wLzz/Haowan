import SwiftUI

/// Settings sheet reachable from the Homescreen: dominant hand and vocab info.
struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(VocabRepository.self) private var vocab
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        @Bindable var settings = settings
        NavigationStack {
            Form {
                Section("Writing hand") {
                    Picker("Dominant hand", selection: $settings.dominantHand) {
                        ForEach(DominantHand.allCases) { hand in
                            Text(hand.label).tag(hand)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text("Moves the quit and hint buttons to the opposite side of the canvas so your writing hand doesn't cover them.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Session length") {
                    Stepper(value: $settings.charactersPerSession, in: 3...10) {
                        Text("\(settings.charactersPerSession) characters per session")
                    }
                }

                Section("Vocabulary") {
                    LabeledContent("Total characters loaded", value: "\(vocab.vocabCount)")
                    if let error = vocab.loadError {
                        Text(error).font(.footnote).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppSettings())
        .environment(VocabRepository())
}
