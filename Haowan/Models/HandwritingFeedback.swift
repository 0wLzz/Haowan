import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

// The structured result shown on the Result page: a star rating plus, when
// the writing was incorrect, a short explanation of what went wrong and how
// to improve (per the PRD's "Product Requirements": "show the correct
// character and a brief reason for mistakes... so users understand what
// went wrong").
//
// When FoundationModels is available, this struct is `@Generable` so the
// on-device model can fill it in directly as constrained, structured output.
// On platforms/OS versions without Foundation Models, a plain Codable
// fallback keeps the rest of the app compiling and working unchanged.
#if canImport(FoundationModels)
@Generable
struct HandwritingFeedback: Equatable {
    @Guide(description: "True only if the drawing is an acceptable match for the target character.")
    var isCorrect: Bool

    @Guide(description: "Star rating: 3 = accurate and confident, 2 = recognizable but flawed, 1 = incorrect or unrecognizable.", .range(1...3))
    var stars: Int

    @Guide(description: "One short, specific sentence describing what went wrong, e.g. a missing stroke or wrong radical placement. Empty string if isCorrect is true.")
    var whatWentWrong: String

    @Guide(description: "One short, encouraging, actionable sentence telling the learner exactly what to do differently next time.")
    var howToImprove: String

    @Guide(description: "One short sentence explaining the correct character by tying it back to its radicals or components.")
    var correctAnswerExplanation: String
}
#else
struct HandwritingFeedback: Equatable, Codable {
    var isCorrect: Bool
    var stars: Int
    var whatWentWrong: String
    var howToImprove: String
    var correctAnswerExplanation: String
}
#endif
