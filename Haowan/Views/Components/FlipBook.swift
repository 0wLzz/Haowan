import SwiftUI

/// An open book whose *pages* turn over the spine — the green cover and the
/// center gutter stay put while one half-page rotates from one side to the
/// other, showing the page you're leaving on its front and the page arriving
/// on its back. Callers provide the left and right page content for any spread
/// index; `index` is the currently open spread.
struct FlipBook<Left: View, Right: View>: View {
    let count: Int
    @Binding var index: Int
    @ViewBuilder var left: (Int) -> Left
    @ViewBuilder var right: (Int) -> Right

    private enum Turn { case forward, backward }

    @State private var turn: Turn?
    @State private var progress: Double = 0

    private let coverInset: CGFloat = 14
    private let flip = Animation.easeInOut(duration: 0.55)

    var body: some View {
        ZStack {
            // Fixed green cover.
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.scholarGreenLight, Theme.scholarGreen],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: .black.opacity(0.28), radius: 20, y: 14)

            pages
                .padding(coverInset)
        }
        .overlay(alignment: .leading) { arrow(next: false) }
        .overlay(alignment: .trailing) { arrow(next: true) }
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { value in
                    if value.translation.width < -40 { startTurn(.forward) }
                    else if value.translation.width > 40 { startTurn(.backward) }
                }
        )
    }

    // MARK: Pages

    private var pages: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let half = w / 2

            ZStack(alignment: .topLeading) {
                // Base spread beneath the turning page.
                HStack(spacing: 0) {
                    pageSurface { left(baseLeftIndex) }.frame(width: half, height: h)
                    pageSurface { right(baseRightIndex) }.frame(width: half, height: h)
                }

                gutter.frame(width: 24, height: h).position(x: w / 2, y: h / 2)

                // The single turning page.
                if let turn {
                    turningPage(turn, half: half, height: h)
                        .frame(width: half, height: h)
                        .position(x: turn == .forward ? w * 0.75 : w * 0.25, y: h / 2)
                }
            }
        }
    }

    @ViewBuilder
    private func turningPage(_ turn: Turn, half: CGFloat, height: CGFloat) -> some View {
        switch turn {
        case .forward:
            FlippingSheet(progress: progress, forward: true, anchor: .leading,
                          front: { pageSurface { right(index) } },
                          back: { pageSurface { left(index + 1) } })
        case .backward:
            FlippingSheet(progress: progress, forward: false, anchor: .trailing,
                          front: { pageSurface { left(index) } },
                          back: { pageSurface { right(index - 1) } })
        }
    }

    // While a page is mid-turn, the layer underneath already shows the
    // destination on the revealed side and the current page on the covered side.
    private var baseLeftIndex: Int {
        switch turn {
        case .backward: return index - 1
        default: return index
        }
    }

    private var baseRightIndex: Int {
        switch turn {
        case .forward: return index + 1
        default: return index
        }
    }

    // MARK: Chrome

    private func pageSurface<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.paper)
            .overlay(
                Rectangle()
                    .strokeBorder(Theme.gold.opacity(0.18), lineWidth: 1)
                    .padding(8)
            )
    }

    private var gutter: some View {
        LinearGradient(
            colors: [.clear, .black.opacity(0.22), .black.opacity(0.28), .black.opacity(0.22), .clear],
            startPoint: .leading, endPoint: .trailing
        )
    }

    @ViewBuilder
    private func arrow(next: Bool) -> some View {
        let enabled = turn == nil && (next ? index < count - 1 : index > 0)
        Button {
            startTurn(next ? .forward : .backward)
        } label: {
            Image(systemName: next ? "chevron.right" : "chevron.left")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.paper)
                .padding(14)
                .background(.black.opacity(0.25), in: Circle())
        }
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0)
        .padding(.horizontal, 2)
    }

    // MARK: Turning

    private func startTurn(_ direction: Turn) {
        guard turn == nil else { return }
        let target = direction == .forward ? index + 1 : index - 1
        guard (0..<count).contains(target) else { return }

        turn = direction
        progress = 0
        withAnimation(flip) {
            progress = 1
        } completion: {
            index = target
            turn = nil
            progress = 0
        }
    }
}

/// A half-page that rotates around one edge, cross-fading between a front and
/// a back face exactly at the halfway point. Conforms to `Animatable` so the
/// face swap tracks the live rotation instead of snapping at the end.
private struct FlippingSheet<Front: View, Back: View>: View, Animatable {
    var progress: Double
    let forward: Bool
    let anchor: UnitPoint
    @ViewBuilder var front: () -> Front
    @ViewBuilder var back: () -> Back

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        let angle = (forward ? -180.0 : 180.0) * progress
        let showBack = progress > 0.5

        ZStack {
            front()
                .opacity(showBack ? 0 : 1)
            back()
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showBack ? 1 : 0)
        }
        // A little shading as the page lifts, deepest edge-on — applied before
        // the rotation so it turns with the page.
        .overlay(Color.black.opacity(0.14 * (1 - abs(progress - 0.5) * 2)))
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), anchor: anchor, perspective: 0.35)
    }
}
