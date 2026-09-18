import SwiftUI

/// "Homescreen" per the spec: the illustrated title scene, with the
/// characters-learned badge at the top-left, the Settings entry point at the
/// top-right (left/right hand + vocab count), and the call to start a session.
struct HomeScreenView: View {
    @Environment(AppState.self) private var appState
    @Environment(VocabRepository.self) private var vocab
    @Environment(AppSettings.self) private var settings
    @State private var showSettings = false

    var body: some View {
        ZStack {
            // Illustrated backdrop (amber wall, window, floor, Mr. Li, vase).
            HomeSceneView()
                .ignoresSafeArea()

            VStack {
                // Top controls: learned badge (left) + settings (right).
                HStack(alignment: .top) {
                    StatBadgeView(learned: appState.learnedCount, total: vocab.vocabCount)
                    
                    Spacer()
                    
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.paper)
                            .padding(12)
                            .background(Theme.scholarGreen.opacity(0.92), in: Circle())
                            .overlay(Circle().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
                            .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                // Call to action, sitting over the floor.
                VStack(spacing: 10) {
                    Button {
                        let items = vocab.items(forDay: appState.currentDay, size: settings.charactersPerSession)
                        appState.startSession(items: items)
                    } label: {
                        Label("Start Writing", systemImage: "pencil.tip")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: 280)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.scholarGreen)
                    .disabled(vocab.allItems.isEmpty)

                    Text("Day \(appState.currentDay) awaits — the people need a scholar who can write.")
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Theme.ink.opacity(0.8))
                        .padding(.horizontal, 40)

                    if let error = vocab.loadError {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 32)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

#Preview {
    HomeScreenView()
        .environment(AppState())
        .environment(VocabRepository())
        .environment(AppSettings())
}
