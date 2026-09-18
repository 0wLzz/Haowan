import SwiftUI

/// The illustrated home backdrop, composed from the layered artwork the
/// designer exported (amber wall, round landscape window, cream floor,
/// Mr. Li at his writing table, and the painted vase). Laying the pieces
/// out proportionally — rather than baking in one flat PNG — keeps the scene
/// crisp at every iPad size and lets the title sit as real, localizable text.
struct HomeSceneView: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                // Wall + floor.
                Theme.amber.ignoresSafeArea()
                VStack(spacing: 0) {
                    Spacer()
                    layeredImage("Floor", fallback: Theme.cream)
                        .frame(height: h * 0.40)
                }
                .ignoresSafeArea()

                // Round landscape window, upper-left.
                image("Windows")
                    .frame(width: w * 0.17)
                    .position(x: w * 0.15, y: h * 0.26)

                // Title.
                Text("Haowan!")
                    .font(.haowanTitle(min(w * 0.09, 80)))
                    .foregroundStyle(Theme.paper)
                    .shadow(color: Theme.amberDeep.opacity(0.35), radius: 1, y: 2)
                    .position(x: w * 0.5, y: h * 0.20)

                // The painted vase, standing on the floor to the right.
                image("Vase")
                    .frame(height: h * 0.42)
                    .position(x: w * 0.82, y: h * 0.5)

                // Mr. Li at his table, centered on the floor line.
                image("MrLi")
                    .frame(width: w * 0.5)
                    .position(x: w * 0.5, y: h * 0.58)
            }
        }
    }

    private func image(_ name: String) -> some View {
        Group {
            if let ui = UIImage(named: name) {
                Image(uiImage: ui).resizable().aspectRatio(contentMode: .fit)
            } else {
                Color.clear
            }
        }
    }

    @ViewBuilder
    private func layeredImage(_ name: String, fallback: Color) -> some View {
        if let ui = UIImage(named: name) {
            Image(uiImage: ui).resizable().aspectRatio(contentMode: .fill)
        } else {
            fallback
        }
    }
}

#Preview {
    HomeSceneView()
}
