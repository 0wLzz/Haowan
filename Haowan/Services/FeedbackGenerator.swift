import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Turns an objective `HandwritingAnalysis` into learner-facing feedback
/// using Apple's on-device Foundation Models framework, with a deterministic
/// rule-based fallback so the app is always demoable — Foundation Models
/// requires Apple Intelligence to be enabled on a supported device, and is
/// reported `.unavailable` in Simulator and on unsupported hardware.
@MainActor
final class FeedbackGenerator {

    /// Whether on-device generative feedback can be used right now.
    var isModelAvailable: Bool {
        #if canImport(FoundationModels)
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
        #else
        return false
        #endif
    }

    func generateFeedback(for analysis: HandwritingAnalysis, target: VocabItem) async -> HandwritingFeedback {
        #if canImport(FoundationModels)
        if isModelAvailable {
            do {
                return try await generateWithFoundationModel(analysis: analysis, target: target)
            } catch {
                // Model declined, timed out, or produced unusable output —
                // fall back rather than leaving the learner without feedback.
                return Self.fallbackFeedback(analysis: analysis, target: target)
            }
        }
        #endif
        return Self.fallbackFeedback(analysis: analysis, target: target)
    }

    #if canImport(FoundationModels)
    private func generateWithFoundationModel(analysis: HandwritingAnalysis, target: VocabItem) async throws -> HandwritingFeedback {
        let instructions = """
        You are a warm, encouraging Chinese writing tutor inside a game where the \
        learner plays a scholar in imperial China writing for the people. You are \
        given an OBJECTIVE analysis of a stroke drawing that already determined \
        whether on-device handwriting recognition matched the target character, \
        along with stroke counts and timing. Do not contradict that analysis — \
        your job is only to explain it kindly and specifically, referencing the \
        character's components when it helps. Keep every field to one short, \
        plain-language sentence. Never mention that you are an AI or a model.
        """

        let session = LanguageModelSession(instructions: instructions)

        let prompt = """
        Target character: \(target.primaryCharacter) (pinyin: \(target.pinyin), meaning: "\(target.meaning)")
        Component/history note: \(target.mnemonicHistory)

        Objective analysis of the learner's drawing:
        - Recognizer's best reading of the drawing: \(analysis.recognizedText?.isEmpty == false ? analysis.recognizedText! : "unrecognized")
        - Matched the target character: \(analysis.matchesTarget)
        - Strokes drawn: \(analysis.strokeCount)
        - Time taken: \(String(format: "%.1f", analysis.duration)) seconds
        - Recognizer confidence (0-1): \(String(format: "%.2f", analysis.confidence))

        Write the learner's feedback now, consistent with the analysis above.
        """

        let response = try await session.respond(to: prompt, generating: HandwritingFeedback.self)
        return response.content
    }
    #endif

    /// Deterministic, rule-based feedback used whenever Foundation Models
    /// isn't available (Simulator, older OS, Apple Intelligence disabled).
    static func fallbackFeedback(analysis: HandwritingAnalysis, target: VocabItem) -> HandwritingFeedback {
        let isCorrect = analysis.matchesTarget && analysis.confidence > 0.5
        let stars: Int = isCorrect ? (analysis.confidence > 0.85 ? 3 : 2) : 1

        let explanation = "\(target.primaryCharacter) (\(target.pinyin)) means \"\(target.meaning)\". \(target.mnemonicHistory)"

        guard !isCorrect else {
            return HandwritingFeedback(
                isCorrect: true,
                stars: stars,
                whatWentWrong: "",
                howToImprove: "Nice and steady — try writing it a little faster next time while keeping the strokes clean.",
                correctAnswerExplanation: explanation
            )
        }

        let reason: String
        if analysis.strokeCount == 0 {
            reason = "No strokes were detected on the page — the canvas looked empty when you submitted."
        } else if let text = analysis.recognizedText, !text.isEmpty {
            reason = "The recognizer read this as \"\(text)\" instead of \(target.primaryCharacter), so a component or proportion likely doesn't match yet."
        } else {
            reason = "The strokes weren't recognizable as \(target.primaryCharacter) yet — double-check the stroke order and proportions."
        }

        return HandwritingFeedback(
            isCorrect: false,
            stars: stars,
            whatWentWrong: reason,
            howToImprove: "Open the hint card to see \(target.primaryCharacter)'s components, then trace it once before writing it freehand.",
            correctAnswerExplanation: explanation
        )
    }
}
