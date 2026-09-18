import Foundation
import Observation

enum AppRoute: Hashable {
    case home
    case writing
    case result
}

/// App-wide navigation and session state: which screen is showing, which
/// characters are queued for "today", and the most recent grading result.
@Observable
@MainActor
final class AppState {
    var route: AppRoute = .home
    var currentDay: Int = UserDefaults.standard.integer(forKey: "progress.currentDay") == 0
        ? 1 : UserDefaults.standard.integer(forKey: "progress.currentDay")

    var sessionQueue: [VocabItem] = []
    var currentIndex: Int = 0
    /// Every character graded so far today, shown together in the end-of-day
    /// practice book.
    var dayResults: [CharacterResult] = []
    var learnedCount: Int = UserDefaults.standard.integer(forKey: "progress.learnedCount")

    var currentItem: VocabItem? {
        guard sessionQueue.indices.contains(currentIndex) else { return nil }
        return sessionQueue[currentIndex]
    }

    func startSession(items: [VocabItem]) {
        guard !items.isEmpty else { return }
        sessionQueue = items
        currentIndex = 0
        dayResults = []
        route = .writing
    }

    /// Records one graded character, then either advances to the next
    /// character or — when the day's queue is finished — opens the book.
    func recordResult(item: VocabItem, feedback: HandwritingFeedback, drawingPNG: Data?) {
        dayResults.append(CharacterResult(item: item, feedback: feedback, drawingPNG: drawingPNG))
        if feedback.isCorrect {
            learnedCount += 1
            UserDefaults.standard.set(learnedCount, forKey: "progress.learnedCount")
        }

        if currentIndex + 1 < sessionQueue.count {
            currentIndex += 1
            route = .writing
        } else {
            route = .result
        }
    }

    /// Closes the book at the end of the day and returns home.
    ///
    /// Deliberately does NOT clear `dayResults`/`sessionQueue` here: the book
    /// is still animating out while `route` changes, and wiping the array it
    /// renders from causes an index-out-of-range crash. `startSession` resets
    /// them for the next day.
    func finishDay() {
        currentDay += 1
        UserDefaults.standard.set(currentDay, forKey: "progress.currentDay")
        currentIndex = 0
        route = .home
    }

    func quitToHome() {
        sessionQueue = []
        currentIndex = 0
        dayResults = []
        route = .home
    }
}
