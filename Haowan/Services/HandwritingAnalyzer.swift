import Foundation
import PencilKit

/// Objective, non-generative measurements of a single drawing, produced by
/// PencilKit's on-device stroke recognizer (see Apple's "Building a
/// handwriting recognition experience with PencilKit" / "Read Between the
/// Strokes with PencilKit"). This is deliberately kept separate from
/// `FeedbackGenerator`: PencilKit decides *what was drawn*, Foundation
/// Models only explains *why it matters* to the learner.
struct HandwritingAnalysis {
    var recognizedText: String?
    var matchesTarget: Bool
    var strokeCount: Int
    var duration: TimeInterval
    var confidence: Double
}

@MainActor
final class HandwritingAnalyzer {
    private lazy var recognizer = PKStrokeRecognizer(
        preferredLanguages: [Locale.Language(languageCode: .chinese, script: .hanSimplified)]
    )

    func analyze(drawing: PKDrawing, target: VocabItem) async -> HandwritingAnalysis {
        let strokes = drawing.strokes
        guard !strokes.isEmpty else {
            return HandwritingAnalysis(recognizedText: nil, matchesTarget: false, strokeCount: 0, duration: 0, confidence: 0)
        }

        await recognizer.updateDrawing(drawing)
        let recognizedText = await recognizer.recognizedText()
        let targetChar = target.primaryCharacter

        var matches = recognizedText?.contains(targetChar) ?? false
        var confidence: Double = matches ? 0.9 : 0.0

        if !matches {
            let results = await recognizer.search(targetChar, fullWordsOnly: false, caseMatchingOnly: false)
            if !results.isEmpty {
                matches = true
                confidence = 0.65
            } else {
                confidence = 0.15
            }
        }

        let timestamps = strokes.map(\.path.creationDate)
        let duration = (timestamps.max() ?? Date()).timeIntervalSince(timestamps.min() ?? Date())

        return HandwritingAnalysis(
            recognizedText: recognizedText,
            matchesTarget: matches,
            strokeCount: strokes.count,
            duration: max(duration, 0),
            confidence: confidence
        )
    }
}
