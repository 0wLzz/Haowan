import SwiftUI

/// Root of the app: owns the shared state objects and switches between the
/// Homescreen (menu), the writing Homepage (gameplay), and the ResultPage.
struct ContentView: View {
    @State private var appState = AppState()
    @State private var settings = AppSettings()
    @State private var vocab = VocabRepository()

    var body: some View {
        Group {
            switch appState.route {
            case .home:
                HomeScreenView()
            case .writing:
                WritingTaskView()
            case .result:
                ResultView()
            }
        }
        .environment(appState)
        .environment(settings)
        .environment(vocab)
        .animation(.easeInOut, value: appState.route)
    }
}

#Preview {
    ContentView()
}
