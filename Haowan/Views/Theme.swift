import SwiftUI

/// Colors sampled from the "Haowan!" concept art (warm amber walls, cream
/// floor/paper, forest-green scholar robes, gold accents).
enum Theme {
    static let amber = Color(red: 0.80, green: 0.56, blue: 0.24)
    static let amberDeep = Color(red: 0.70, green: 0.46, blue: 0.18)
    static let cream = Color(red: 0.96, green: 0.90, blue: 0.76)
    static let paper = Color(red: 0.97, green: 0.94, blue: 0.87)
    static let ink = Color(red: 0.11, green: 0.10, blue: 0.09)
    static let scholarGreen = Color(red: 0.16, green: 0.31, blue: 0.19)
    static let scholarGreenLight = Color(red: 0.29, green: 0.47, blue: 0.31)
    static let gold = Color(red: 0.85, green: 0.68, blue: 0.32)

    static let backgroundGradient = LinearGradient(
        colors: [amber, amber, cream],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Font {
    static func haowanTitle(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
}
