import Foundation

/// One completed character attempt from a day's session, collected so the
/// end-of-day practice book can show every page: the target character, the
/// feedback that was generated, and a PNG snapshot of what the learner
/// actually wrote on the paper.
struct CharacterResult: Identifiable {
    let id = UUID()
    let item: VocabItem
    let feedback: HandwritingFeedback
    /// The learner's ink, rendered from the canvas at submit time. `nil` if
    /// the page was empty or couldn't be captured.
    let drawingPNG: Data?
}
