import Foundation
import Observation

/// Loads and slices the bundled Hanzi vocabulary list (`Resources/Hanzi.json`).
@Observable
@MainActor
final class VocabRepository {
    private(set) var allItems: [VocabItem] = []
    private(set) var loadError: String?

    init() {
        load()
    }

    private func load() {
        guard let url = Bundle.main.url(forResource: "Hanzi", withExtension: "json") else {
            loadError = "Hanzi.json was not found in the app bundle."
            return
        }
        do {
            let data = try Data(contentsOf: url)
            allItems = try JSONDecoder().decode([VocabItem].self, from: data)
        } catch {
            loadError = "Couldn't read Hanzi.json: \(error.localizedDescription)"
        }
    }

    var vocabCount: Int { allItems.count }

    /// A stable slice of vocabulary for a given "day", matching the PRD's
    /// proposed flow ("The user chooses a day to learn"). Wraps around once
    /// every character has been used at least once.
    func items(forDay day: Int, size: Int) -> [VocabItem] {
        guard !allItems.isEmpty else { return [] }
        let count = min(max(size, 1), allItems.count)
        let start = ((max(day, 1) - 1) * count) % allItems.count
        var slice: [VocabItem] = []
        var index = start
        for _ in 0..<count {
            slice.append(allItems[index])
            index = (index + 1) % allItems.count
        }
        return slice
    }
}
