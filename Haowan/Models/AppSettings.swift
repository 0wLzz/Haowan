import Foundation
import Observation

enum DominantHand: String, CaseIterable, Identifiable, Codable {
    case left, right
    var id: Self { self }
    var label: String { self == .left ? "Left-handed" : "Right-handed" }
}

/// User-facing preferences from the "Homescreen: Settings" spec — writing
/// hand and how many characters make up one writing session.
@Observable
@MainActor
final class AppSettings {
    var dominantHand: DominantHand {
        didSet { UserDefaults.standard.set(dominantHand.rawValue, forKey: Keys.hand) }
    }
    var charactersPerSession: Int {
        didSet { UserDefaults.standard.set(charactersPerSession, forKey: Keys.sessionSize) }
    }

    private enum Keys {
        static let hand = "settings.dominantHand"
        static let sessionSize = "settings.charactersPerSession"
    }

    init() {
        let store = UserDefaults.standard
        if let raw = store.string(forKey: Keys.hand), let hand = DominantHand(rawValue: raw) {
            dominantHand = hand
        } else {
            dominantHand = .right
        }
        let storedSize = store.integer(forKey: Keys.sessionSize)
        charactersPerSession = storedSize == 0 ? 5 : storedSize
    }
}
