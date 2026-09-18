import SwiftUI

/// Draws the classic "mi zi ge" (米字格) guide grid — a border, center
/// cross, and corner-to-corner diagonals — that Chinese workbooks use to
/// teach stroke proportion, matching the writing-paper mockup.
struct GridPaperView: View {
    var lineColor: Color = Theme.gold.opacity(0.5)
    var borderColor: Color = Theme.gold

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size).insetBy(dx: 2, dy: 2)
            Canvas { ctx, _ in
                let border = Path(roundedRect: rect, cornerRadius: 8)
                ctx.stroke(border, with: .color(borderColor), lineWidth: 2)

                var guides = Path()
                guides.move(to: CGPoint(x: rect.midX, y: rect.minY))
                guides.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
                guides.move(to: CGPoint(x: rect.minX, y: rect.midY))
                guides.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
                guides.move(to: CGPoint(x: rect.minX, y: rect.minY))
                guides.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
                guides.move(to: CGPoint(x: rect.maxX, y: rect.minY))
                guides.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

                ctx.stroke(guides, with: .color(lineColor), style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            }
        }
        .background(Theme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    GridPaperView().frame(width: 300, height: 380).padding()
}
