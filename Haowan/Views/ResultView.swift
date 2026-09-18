import SwiftUI

/// End-of-day practice book. Each spread is one character the learner wrote
/// today: the left page compares their writing with the correct character,
/// the right page shows the accuracy stars and improvement tips. Paging
/// through the book reviews the whole day before returning home.
struct ResultView: View {
    @Environment(AppState.self) private var appState

    @State private var spread = 0

    private var results: [CharacterResult] { appState.dayResults }
    private var correctCount: Int { results.filter { $0.feedback.isCorrect }.count }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            if results.isEmpty {
                ProgressView()
            } else {
                VStack(spacing: 14) {
                    header

                    book
                        .padding(.horizontal, 8)

                    footer
                }
                .padding(20)
                .frame(maxWidth: 900)
            }
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(spacing: 4) {
            Text("Day \(appState.currentDay) · Your Practice Book")
                .font(.haowanTitle(26))
                .foregroundStyle(Theme.paper)
            Text("You wrote \(correctCount) of \(results.count) characters well.")
                .font(.subheadline)
                .foregroundStyle(Theme.paper.opacity(0.8))
        }
    }

    // MARK: Book

    private var book: some View {
        FlipBook(
            count: results.count,
            index: $spread,
            left: { i in writingPage(for: results[i]) },
            right: { i in feedbackPage(for: results[i]) }
        )
        .aspectRatio(1.5, contentMode: .fit)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // Left page: the learner's ink beside the correct character.
    private func writingPage(for result: CharacterResult) -> some View {
        VStack(spacing: 14) {
            Text("\(result.item.pinyin) · \(result.item.meaning)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.scholarGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            VStack(spacing: 14) {
                practiceSquare(caption: "You wrote") {
                    if let data = result.drawingPNG, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                    } else {
                        Text("—")
                            .font(.largeTitle)
                            .foregroundStyle(Theme.ink.opacity(0.3))
                    }
                }
                practiceSquare(caption: "Correct") {
                    Text(result.item.primaryCharacter)
                        .font(.system(size: 200, weight: .regular))
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                        .foregroundStyle(Theme.ink)
                        .padding(6)
                }
            }
            Spacer(minLength: 0)
        }
    }

    // Right page: accuracy and how to do better next time.
    private func feedbackPage(for result: CharacterResult) -> some View {
        let f = result.feedback
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Accuracy")
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text(accuracyWord(for: f.stars))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.scholarGreen)
            }
            StarRatingView(stars: f.stars, size: 26)

            Divider()

            if !f.whatWentWrong.isEmpty {
                tip(title: "What went wrong",
                    systemImage: "exclamationmark.triangle.fill",
                    tint: .orange,
                    text: f.whatWentWrong)
            }
            tip(title: "How to improve",
                systemImage: "arrow.up.forward.circle.fill",
                tint: Theme.scholarGreen,
                text: f.howToImprove)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func practiceSquare<Content: View>(caption: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 6) {
            Text(caption)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.ink.opacity(0.55))
            ZStack {
                GridPaperView()
                content()
            }
            .aspectRatio(1, contentMode: .fit)
        }
    }

    private func tip(title: String, systemImage: String, tint: Color, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.ink)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(results.indices, id: \.self) { i in
                    Circle()
                        .fill(i == spread ? Theme.paper : Theme.paper.opacity(0.35))
                        .frame(width: 8, height: 8)
                }
            }

            Button {
                appState.finishDay()
            } label: {
                Label("Finish for Today", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: 280)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.scholarGreen)
        }
    }

    // MARK: Helpers

    private func accuracyWord(for stars: Int) -> String {
        switch stars {
        case 3: return "Excellent"
        case 2: return "Good"
        default: return "Keep practicing"
        }
    }
}

#Preview {
    let state = AppState()
    let vocab = VocabRepository()
    let items = vocab.items(forDay: 1, size: 3)
    state.sessionQueue = items
    state.dayResults = items.enumerated().map { index, item in
        CharacterResult(
            item: item,
            feedback: HandwritingFeedback(
                isCorrect: index != 0,
                stars: index == 0 ? 1 : (index == 1 ? 2 : 3),
                whatWentWrong: index == 0 ? "The bottom component was missing a stroke." : "",
                howToImprove: "Slow down on the last two strokes and keep them inside the grid.",
                correctAnswerExplanation: item.mnemonicHistory
            ),
            drawingPNG: nil
        )
    }
    return ResultView().environment(state)
}
