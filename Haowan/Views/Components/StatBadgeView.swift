import SwiftUI

/// Compact "characters learned" badge for the top-left of the Homescreen:
/// a brush/character icon with the running count, replacing the old inline
/// progress row.
struct StatBadgeView: View {
    let learned: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "character.book.closed.fill.zh")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Theme.gold)
                .font(.title3)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Text("\(learned) learned")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.paper)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Theme.scholarGreen.opacity(0.92), in: Capsule())
        .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.6), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 5, y: 3)
    }
}

#Preview {
    StatBadgeView(learned: 7, total: 40)
        .padding()
//        .background(Theme.amber)
}
