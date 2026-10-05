import SwiftUI

struct InsightFrameStack: View {
    let insights: [Insight]
    var onTap: (() -> Void)?
    var namespace: Namespace.ID?

    @State private var topIndex = 0
    @State private var dragOffset: CGSize = .zero
    @State private var dragRotation: Double = 0
    @State private var isDragging = false
    @State private var expandAmount: CGFloat = 0
    @State private var isThrowing = false
    @State private var isViewerPresented = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    static let cardWidth: CGFloat = 220
    static let cardHeight: CGFloat = 220
    private static let stackHeadroom: CGFloat = 40
    private let maxVisibleDepth = 3

    var body: some View {
        if insights.isEmpty {
            emptyState
        } else {
            stack
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.tap()
                    isViewerPresented = true
                }
                .fullScreenCover(isPresented: $isViewerPresented) {
                    FrameViewer(insights: insights, startIndex: topIndex)
                }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "sparkles.rectangle.stack")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("No insights yet")
                .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
            Text("Share a Reel to discover places")
                .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.mutedMetadata)
        }
        .frame(width: Self.cardWidth, height: Self.cardHeight + Self.stackHeadroom)
    }

    private var stack: some View {
        ZStack(alignment: .bottom) {
            ForEach(insights.indices, id: \.self) { index in
                let depth = depth(of: index)
                let isTop = index == topIndex

                StackCard(
                    insight: insights[index],
                    depth: depth,
                    maxVisibleDepth: maxVisibleDepth,
                    isTop: isTop,
                    dragOffset: isTop ? dragOffset : .zero,
                    dragRotation: isTop ? dragRotation : 0,
                    expandAmount: isTop ? expandAmount : 0,
                    isThrowing: isTop && isThrowing,
                    reduceMotion: reduceMotion,
                    namespace: namespace
                )
                .zIndex(Double(insights.count - depth))
            }
        }
        .frame(
            width: Self.cardWidth,
            height: Self.cardHeight + Self.stackHeadroom
        )
        .contentShape(Rectangle())
        .gesture(topCardGesture)
        .animation(Motion.smooth.animation, value: expandAmount)
        .animation(Motion.standard.animation, value: topIndex)
        .accessibilityIdentifier("insightFrameStack")
    }

    private var topCardGesture: some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { value in
                if !isDragging {
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    guard horizontal > 10 || vertical > 10 else { return }
                    isDragging = true
                    Haptics.cardPress()
                }
                dragOffset = value.translation

                if !reduceMotion {
                    dragRotation = Double(value.translation.width / Self.cardWidth) * 12
                }

                if value.translation.height < 0, abs(value.translation.height) > abs(value.translation.width) {
                    expandAmount = min(1, -value.translation.height / 140)
                } else {
                    expandAmount = max(0, expandAmount - 0.08)
                }
            }
            .onEnded { value in
                guard isDragging else { return }
                isDragging = false

                let predicted = value.predictedEndTranslation.width
                let velocity = predicted - value.translation.width
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                let shouldThrow = insights.count > 1 && isHorizontal
                    && (abs(predicted) > Self.cardWidth * 0.33 || abs(velocity) > 520)

                if shouldThrow {
                    throwTopCard(toward: predicted)
                } else if reduceMotion {
                    withAnimation(.easeOut(duration: 0.12)) {
                        dragOffset = .zero
                        dragRotation = 0
                        expandAmount = 0
                    }
                } else {
                    withAnimation(Motion.smooth.animation) {
                        dragOffset = .zero
                        dragRotation = 0
                        expandAmount = 0
                    }
                }
            }
    }

    private func throwTopCard(toward predicted: CGFloat) {
        let direction: CGFloat = predicted >= 0 ? 1 : -1

        guard !reduceMotion else {
            topIndex = (topIndex + 1) % insights.count
            dragOffset = .zero
            dragRotation = 0
            expandAmount = 0
            isThrowing = false
            Haptics.cardSnap()
            return
        }

        isThrowing = true
        withAnimation(Motion.hero.animation) {
            dragOffset = CGSize(
                width: direction * (Self.cardWidth + 80),
                height: dragOffset.height * 0.3
            )
            dragRotation = Double(direction) * 22
            expandAmount = 0
        } completion: {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                dragOffset = .zero
                dragRotation = 0
                isThrowing = false
                topIndex = (topIndex + 1) % insights.count
            }
            Haptics.cardSnap()
        }
    }

    private func depth(of index: Int) -> Int {
        (index - topIndex + insights.count) % insights.count
    }
}

private struct StackCard: View {
    let insight: Insight
    let depth: Int
    let maxVisibleDepth: Int
    let isTop: Bool
    let dragOffset: CGSize
    let dragRotation: Double
    let expandAmount: CGFloat
    let isThrowing: Bool
    let reduceMotion: Bool
    var namespace: Namespace.ID?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let depthIndex = CGFloat(min(depth, maxVisibleDepth))
        let baseScale = 1.0 - 0.045 * depthIndex
        let baseOffsetY = -18 * depthIndex
        let baseRotation = Double(depthIndex) * 1.2

        ZStack {
            if let url = insight.thumbnailUrl ?? insight.imageUrl, !url.isEmpty {
                RemoteImage(url: url)
                    .aspectRatio(contentMode: .fill)
                    .ifLet(namespace) { view, ns in
                        view.matchedGeometryEffect(id: "frame-\(insight.id)", in: ns)
                    }
            } else {
                gradientBackground
            }
        }
        .frame(width: InsightFrameStack.cardWidth, height: InsightFrameStack.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .overlay(alignment: .bottom, content: bottomOverlay)
        .scaleEffect(baseScale + (isTop ? (expandAmount * 0.05) : 0))
        .rotationEffect(.degrees(baseRotation + dragRotation))
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : Double(dragOffset.width / InsightFrameStack.cardWidth) * 5),
            axis: (x: 0, y: 1, z: 0),
            anchor: .center,
            perspective: 0.65
        )
        .offset(
            x: dragOffset.width,
            y: baseOffsetY - expandAmount * depthIndex * 25 + dragOffset.height
        )
        .opacity(isThrowing ? 0 : (depth > maxVisibleDepth ? 0 : 1.0 - 0.12 * Double(depthIndex) - Double(expandAmount) * 0.04))
        .shadow(
            color: .black.opacity(isTop ? 0.18 : 0.12),
            radius: isTop ? 24 : (depth == 2 ? 14 : 10),
            y: isTop ? 12 : (depth == 2 ? 6 : 4)
        )
        .animation(Motion.smooth.animation, value: dragOffset)
        .animation(Motion.standard.animation, value: dragRotation)
        .animation(Motion.smooth.animation, value: expandAmount)
        .animation(Motion.hero.animation, value: isThrowing)
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

    private func bottomOverlay() -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                typeBadge
                Spacer()
                if insight.timestamp > 0 {
                    Text(
                        Date(timeIntervalSince1970: insight.timestamp)
                            .formatted(.dateTime.month(.abbreviated).day().hour().minute())
                    )
                    .fontStyle(DesignSystem.Typography.metadata, colorScheme: .light)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
                }
            }

            if !insight.reason.isEmpty {
                Text(insight.reason)
                    .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: .light)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.08), .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var typeBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: insight.type.iconName)
                .font(.system(size: 9, weight: .semibold))
            Text(insight.type.displayName.uppercased())
                .fontStyle(DesignSystem.Typography.stamp)
        }
        .foregroundStyle(.white.opacity(0.95))
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
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