import SwiftUI

struct InsightCard: View {
    let insight: Insight
    var isSelected: Bool = false
    var onTap: (() -> Void)?
    var namespace: Namespace.ID?

    @Environment(\.colorScheme) private var colorScheme
    @State private var dragOffset: CGSize = .zero
    @State private var isPressed = false
    @GestureState private var gestureDrag: CGSize = .zero

    var body: some View {
        ZStack {
            if let url = insight.thumbnailUrl, !url.isEmpty {
                RemoteImage(url: url)
                    .scaleEffect(isPressed ? 1.04 : (isSelected ? 1.02 : 1.0))
                    .animation(Motion.smooth.animation, value: isPressed)
                    .animation(Motion.standard.animation, value: isSelected)
                    .ifLet(namespace) { view, ns in
                        view.matchedGeometryEffect(id: "insight-thumb-\(insight.id)", in: ns)
                    }
            } else {
                gradientBackground
            }

            VStack {
                Spacer()
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        typeBadge
                        Spacer()
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.md)

                    Text(insight.reason)
                        .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                        .foregroundStyle(.white)
                        .lineLimit(3)
                        .shadow(color: .black.opacity(0.35), radius: 8, y: 4)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.bottom, DesignSystem.Spacing.md)
                }
                .background(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.08), .black.opacity(0.65)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .shadow(
            color: .black.opacity(isSelected ? 0.25 : (isPressed ? 0.15 : 0.12)),
            radius: isSelected ? 24 : (isPressed ? 12 : 16),
            y: isSelected ? 12 : (isPressed ? 6 : 8)
        )
        .scaleEffect(isPressed ? 0.96 : (isSelected ? 1.03 : 1.0))
        .rotationEffect(.degrees(dragRotation))
        .offset(dragOffset + gestureDrag)
        .animation(Motion.smooth.animation, value: isPressed)
        .animation(Motion.standard.animation, value: isSelected)
        .animation(Motion.smooth.animation, value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($gestureDrag) { value, state, _ in
                    state = value.translation
                }
                .onChanged { value in
                    dragOffset = value.translation
                    if !isPressed {
                        isPressed = true
                        Haptics.cardPress()
                    }
                }
                .onEnded { value in
                    let velocity = value.velocity.width
                    let shouldDismiss = abs(value.translation.width) > 120 || abs(velocity) > 800

                    withAnimation(Motion.smooth.animation) {
                        dragOffset = .zero
                        isPressed = false
                    }

                    if shouldDismiss {
                        Haptics.cardRelease()
                    }
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    if !isPressed {
                        Haptics.tap()
                        onTap?()
                    }
                }
        )
        .accessibilityLabel(insight.reason)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var gradientBackground: some View {
        let tint = insightTypeTint(insight.type, scheme: colorScheme)
        return LinearGradient(
            colors: [tint.opacity(0.88), tint.opacity(0.45)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay {
            Image(systemName: insight.type.iconName)
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(.white.opacity(0.75))
                .rotationEffect(.degrees(-8))
        }
    }

    private var typeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: insight.type.iconName)
                .font(.system(size: 10, weight: .semibold))
            Text(insight.type.displayName.uppercased())
                .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
        }
        .foregroundStyle(.white.opacity(0.95))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
    }

    private var dragRotation: Double {
        let translation = gestureDrag.width
        let maxRotation = 4.0
        return max(-maxRotation, min(maxRotation, translation / 120 * maxRotation))
}

private func insightTypeTint(_ type: InsightType, scheme: ColorScheme) -> SwiftUI.Color {
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
    return scheme == .dark ? Color(hex: pair.dark) : Color(hex: pair.light)
}
}