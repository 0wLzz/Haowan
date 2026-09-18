import SwiftUI
import PencilKit

/// The gameplay "Homepage": the learner is shown a pinyin syllable and writes
/// the matching hanzi on the rice-paper card to the right. Flipping the paper
/// reveals a hint — the character, its meaning, and where it comes from.
///
/// The room (wall, floor, scholar, vase, and Mrs. Ma looking on) is composed
/// from the exported artwork and positioned proportionally so it stays crisp
/// at every iPad size, matching the concept mockup.
struct WritingTaskView: View {
    @Environment(AppState.self) private var appState
    @Environment(AppSettings.self) private var settings

    @State private var canvasModel = WritingCanvasModel()
    @State private var speaker = PronunciationSpeaker()
    @State private var isFlipped = false
    @State private var isGrading = false
    @State private var showQuitConfirm = false

    private let analyzer = HandwritingAnalyzer()
    private let generator = FeedbackGenerator()

    private var target: VocabItem? { appState.currentItem }

    /// The whole room is authored for a right-handed writer (paper on the
    /// right). For a left-handed writer we mirror every element's horizontal
    /// position, so the paper — and the hand resting on it — moves to the left
    /// and the scene moves clear to the right.
    private var isLeftHanded: Bool { settings.dominantHand == .left }

    private func mirrored(_ fraction: CGFloat) -> CGFloat {
        isLeftHanded ? 1 - fraction : fraction
    }

    var body: some View {
        ZStack {
            Theme.amber.ignoresSafeArea()

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                room(w: w, h: h)

                if let target {
                    pinyinCard(for: target, w: w, h: h)

                    // Sized by width so it never overflows its column, in
                    // landscape or portrait; height follows the paper ratio.
                    // Sits on the writing-hand side (right by default, left when
                    // the learner has set left-handed in Settings).
                    WritingPaperCard(target: target, canvasModel: canvasModel, isFlipped: $isFlipped)
                        .frame(width: w * 0.42)
                        .position(x: mirrored(0.74) * w, y: h * 0.46)

                    controlBar(w: w, h: h)
                        .position(x: mirrored(0.74) * w, y: h * 0.955)
                }
            }
            .disabled(isGrading)

            chrome

            if isGrading {
                ProgressView("Grading your writing…")
                    .padding(24)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        // Moving to the next character keeps this same screen mounted, so the
        // paper must be wiped and unflipped for a fresh attempt.
        .onChange(of: appState.currentIndex) { _, _ in
            canvasModel.clear()
            isFlipped = false
        }
        .confirmationDialog(
            "Leave this task? Your progress on this character won't be saved.",
            isPresented: $showQuitConfirm,
            titleVisibility: .visible
        ) {
            Button("Quit to Home", role: .destructive) { appState.quitToHome() }
            Button("Keep Writing", role: .cancel) {}
        }
    }

    // MARK: Room backdrop
    @ViewBuilder
    private func room(w: CGFloat, h: CGFloat) -> some View {
        // Cream floor across the lower portion of the wall.
        VStack(spacing: 0) {
            Spacer()
            sceneImage("Floor", fill: true)
                .frame(height: h * 0.42)
        }
        .ignoresSafeArea()

        // Scholar at his writing table, then the painted vase beside him.
        sceneImage("MrLi")
            .frame(width: w * 0.30)
            .position(x: mirrored(0.24) * w, y: h * 0.60)

        sceneImage("Vase")
            .frame(height: h * 0.30)
            .position(x: mirrored(0.43) * w, y: h * 0.55)

        // Mrs. Ma, looking on from the foreground.
        sceneImage("Mrs_Ma")
            .frame(height: h * 0.46)
            .position(x: mirrored(0.11) * w, y: h * 0.74)
    }

    @ViewBuilder
    private func sceneImage(_ name: String, fill: Bool = false) -> some View {
        if let ui = UIImage(named: name) {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(contentMode: fill ? .fill : .fit)
        } else {
            Color.clear
        }
    }

    // MARK: Pinyin prompt

    private func pinyinCard(for target: VocabItem, w: CGFloat, h: CGFloat) -> some View {
        Text(target.pinyin)
            .font(.system(size: min(w * 0.075, 96), weight: .regular, design: .rounded))
            .foregroundStyle(Theme.ink)
            .minimumScaleFactor(0.4)
            .lineLimit(1)
            .frame(width: w * 0.40, height: h * 0.20)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Theme.cream, lineWidth: 8)
            )
            .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            .overlay(alignment: .bottomTrailing) {
                speakerButton(for: target)
            }
            .position(x: mirrored(0.27) * w, y: h * 0.17)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Write the character for the sound \(target.pinyin)")
    }

    // Plays the character's Mandarin pronunciation on tap. 44×44pt hit target
    // per iOS/iPadOS controls; audio is never auto-played.
    private func speakerButton(for target: VocabItem) -> some View {
        Button {
            speaker.speak(target.primaryCharacter)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title3)
                .foregroundStyle(Theme.scholarGreen)
                .frame(width: 44, height: 44)
                .background(Theme.cream, in: Circle())
                .overlay(Circle().strokeBorder(Theme.gold.opacity(0.5), lineWidth: 1))
                .shadow(color: .black.opacity(0.15), radius: 3, y: 2)
                .symbolEffect(.bounce, value: speaker.isSpeaking)
        }
        .padding(10)
        .accessibilityLabel("Hear pronunciation")
    }

    // MARK: Controls under the paper

    private func controlBar(w: CGFloat, h: CGFloat) -> some View {
        HStack(spacing: 14) {
            Button {
                withAnimation { isFlipped.toggle() }
            } label: {
                Label(isFlipped ? "Hide Hint" : "Show Hint",
                      systemImage: isFlipped ? "eye.slash.fill" : "lightbulb.fill")
                    .frame(minHeight: 30)
            }
            .buttonStyle(.bordered)
            .tint(Theme.gold)

            Spacer(minLength: 0)

            Button("Clear") { canvasModel.clear() }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(isFlipped || !canvasModel.hasStrokes)

            Button {
                Task { await submit() }
            } label: {
                Label("Submit", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .frame(minHeight: 30)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.scholarGreen)
            .disabled(isFlipped || !canvasModel.hasStrokes)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: Capsule())
        .frame(width: w * 0.42)
    }

    // MARK: Chrome (quit)
    private var chrome: some View {
        VStack {
            // Quit sits opposite the paper, clear of the writing hand.
            HStack(alignment: .top) {
                if isLeftHanded { Spacer() }
                quitButton
                if !isLeftHanded { Spacer() }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var quitButton: some View {
        Button {
            showQuitConfirm = true
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
                .foregroundStyle(Theme.paper)
                .padding(12)
                .background(.black.opacity(0.25), in: Circle())
        }
        .accessibilityLabel("Quit to home")
    }

    private func submit() async {
        guard let target else { return }
        isGrading = true
        let drawing = canvasModel.currentDrawing
        let drawingPNG = canvasModel.drawingPNGData()
        let analysis = await analyzer.analyze(drawing: drawing, target: target)
        let feedback = await generator.generateFeedback(for: analysis, target: target)
        isGrading = false
        appState.recordResult(item: target, feedback: feedback, drawingPNG: drawingPNG)
    }
}

#Preview {
    let state = AppState()
    let vocab = VocabRepository()
    state.startSession(items: vocab.items(forDay: 1, size: 3))
    return WritingTaskView()
        .environment(state)
        .environment(AppSettings())
        .environment(vocab)
}
