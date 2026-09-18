import SwiftUI

/// The rice-paper writing surface on the right of the task screen. The front
/// is the printed mi-zi-ge sheet (`Paper.png`) with a transparent PencilKit
/// canvas laid over the guide grid; flipping the card reveals a hint back that
/// shows the target character, its meaning, and where it comes from.
///
/// The card keeps its printed aspect ratio so the canvas insets line up with
/// the gold border drawn on the artwork.
struct WritingPaperCard: View {
    let target: VocabItem
    var canvasModel: WritingCanvasModel
    @Binding var isFlipped: Bool

    /// 666 × 904 — the source `Paper.png` proportions.
    private let paperAspect: CGFloat = 666.0 / 904.0

    var body: some View {
        ZStack {
            front
                .opacity(isFlipped ? 0 : 1)
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
                .accessibilityHidden(isFlipped)

            back
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
                .accessibilityHidden(!isFlipped)
        }
        .aspectRatio(paperAspect, contentMode: .fit)
        .animation(.easeInOut(duration: 0.55), value: isFlipped)
    }

    // MARK: Front — the writing sheet

    private var front: some View {
        GeometryReader { geo in
            ZStack {
                paperImage
                // The canvas sits inside the printed gold border. Insets are
                // fractions of the card, which tracks the paper's aspect ratio.
                HanziCanvasView(model: canvasModel, showsGuideGrid: false, showsToolPicker: false)
                    .padding(EdgeInsets(
                        top: geo.size.height * 0.075,
                        leading: geo.size.width * 0.085,
                        bottom: geo.size.height * 0.08,
                        trailing: geo.size.width * 0.085
                    ))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Writing paper. Draw the character for \(target.pinyin).")
    }

    @ViewBuilder
    private var paperImage: some View {
        if let ui = UIImage(named: "Paper") {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            // Fallback keeps the screen usable if the art is missing.
            GridPaperView()
                .shadow(color: .black.opacity(0.15), radius: 10, y: 6)
        }
    }

    // MARK: Back — the hint

    private var back: some View {
        VStack(spacing: 16) {
            Text(target.primaryCharacter)
                .font(.system(size: 120, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("(\(target.meaning))")
                .font(.title2)
                .foregroundStyle(Theme.ink.opacity(0.85))

            Text("\(target.pinyin)")
                .font(.title3.weight(.medium))
                .foregroundStyle(Theme.scholarGreen)

            Divider()
                .padding(.horizontal, 8)

            Text("**History:** \(target.mnemonicHistory)")
                .font(.body)
                .foregroundStyle(Theme.ink.opacity(0.85))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hint. The character is \(target.primaryCharacter), meaning \(target.meaning). History: \(target.mnemonicHistory)")
    }
}

#Preview {
    struct Wrap: View {
        @State private var flipped = false
        let item = VocabItem(
            hanzi: "我", pinyin: "Wǒ", meaning: "Me",
            mnemonicHistory: "Originally an oracle bone pictogram depicting a saw-toothed weapon or rake. Over time, it was borrowed for the pronoun 'I'."
        )
        var body: some View {
            WritingPaperCard(target: item, canvasModel: WritingCanvasModel(), isFlipped: $flipped)
                .frame(height: 640)
                .padding()
                .background(Theme.amber)
                .onTapGesture { flipped.toggle() }
        }
    }
    return Wrap()
}
