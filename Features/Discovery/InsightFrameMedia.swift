import SwiftUI

struct InsightFrameMedia: View {
    let insight: Insight
    var contentMode: ContentMode = .fill
    var namespace: Namespace.ID?
    var cornerRadius: CGFloat = DesignSystem.Radius.md

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            if let url = insight.imageUrl ?? insight.thumbnailUrl, !url.isEmpty {
                RemoteImage(url: url)
                    .aspectRatio(contentMode: contentMode)
                    .ifLet(namespace) { view, ns in
                        view.matchedGeometryEffect(id: "frame-media-\(insight.id)", in: ns)
                    }
            } else {
                gradientBackground
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .shadowCard()
    }

    private var gradientBackground: some View {
        let tint = insightTypeTint(insight.type)
        return LinearGradient(
            colors: [tint.opacity(0.88), tint.opacity(0.45)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: insight.type.iconName)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(.white.opacity(0.75))
                .rotationEffect(.degrees(-8))
        }
    }

    private func insightTypeTint(_ type: InsightType) -> SwiftUI.Color {
        let colors: [InsightType: (light: String, dark: String)] = [
            .place: ("FF9F0A", "FFB340"),
            .business: ("0A84FF", "4DA6FF"),
            .restaurant: ("FF3B30", "FF6B5A"),
            .cafe: ("30D158", "64E67E"),
            .bar: ("AF52DE", "C77DFF"),
            .event: ("FF2D92", "FF66B3"),
            .activity: ("5E5CE6", "8A88FF"),
            .shop: ("BF5AF2", "D48BFF"),
            .landmark: ("FF9500", "FFB340"),
            .transit: ("007AFF", "4DA6FF"),
            .unknown: ("8E8E93", "AEAEB2"),
        ]
        let pair = colors[type] ?? ("8E8E93", "AEAEB2")
        return colorScheme == .dark ? Color(hex: pair.dark) : Color(hex: pair.light)
    }
}