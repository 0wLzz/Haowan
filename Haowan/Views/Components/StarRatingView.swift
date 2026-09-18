import SwiftUI

/// The Result page's star rating — "how many stars do you get based on the
/// accuracy" per the spec.
struct StarRatingView: View {
    let stars: Int
    let maxStars: Int = 3
    var size: CGFloat = 44

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...maxStars, id: \.self) { index in
                Image(systemName: index <= stars ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundStyle(index <= stars ? Theme.gold : Theme.gold.opacity(0.3))
                    .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double(index) * 0.12), value: stars)
            }
        }
    }
}

#Preview {
    StarRatingView(stars: 2).padding().background(Theme.amber)
}
