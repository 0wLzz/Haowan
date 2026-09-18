import Foundation

/// One vocabulary entry, decoded from the bundled `Hanzi.json` (currently an
/// HSK1-derived list). Each entry already carries a short "mnemonic_history"
/// note, which the app leans on heavily for hints and post-writing feedback.
struct VocabItem: Identifiable, Codable, Hashable {
    var id: String { hanzi }
    let hanzi: String
    let pinyin: String
    let meaning: String
    let mnemonicHistory: String

    enum CodingKeys: String, CodingKey {
        case hanzi, pinyin, meaning
        case mnemonicHistory = "mnemonic_history"
    }

    /// The character with any parenthetical alt-forms stripped,
    /// e.g. "这(这儿)" -> "这".
    var primaryCharacter: String {
        String(hanzi.prefix { $0 != "(" })
    }
}
