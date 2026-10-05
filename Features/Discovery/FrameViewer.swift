import SwiftUI

struct FrameViewer: View {
    let insights: [Insight]
    var startIndex: Int = 0
    var reelId: String?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    @State private var index: Int
    @State private var dragOffset: CGSize = .zero
    @State private var activeAxis: SwipeAxis?
    @State private var isDismissing = false

    private enum SwipeAxis {
        case horizontal
        case vertical
    }

    init(insights: [Insight], startIndex: Int, reelId: String? = nil) {
        self.insights = insights
        self.reelId = reelId
        _index = State(initialValue: min(max(startIndex, 0), max(insights.count - 1, 0)))
    }

    var body: some View {
        ZStack(alignment: .top) {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            content
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if insights.isEmpty {
                dismiss()
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: index)
        .simultaneousGesture(viewerGesture)
        .animation(reduceMotion ? .easeOut(duration: 0.15) : Motion.smooth.animation, value: index)
    }

    private var content: some View {
        GeometryReader { geo in
            VStack(spacing: DesignSystem.Spacing.lg) {
                headerRow
                Spacer()
                if let insight = currentInsight {
                    InsightFrameMedia(insight: insight, contentMode: .fit, namespace: nil)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: geo.size.height * 0.55)
                    infoSection(insight)
                }
                Spacer()
            }
            .padding(DesignSystem.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(isDismissing ? dismissScale : 1)
            .opacity(isDismissing ? dismissOpacity : 1)
            .offset(x: dragOffset.width, y: dragOffset.height)
        }
        .background(Color.clear)
    }

    private var headerRow: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
            if let insight = currentInsight {
                typeChip(insight)
            }
            Spacer(minLength: DesignSystem.Spacing.xs)
            if insights.count > 1 {
                Text("\(index + 1) of \(insights.count)")
                    .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            closeButton
        }
    }

    private func infoSection(_ insight: Insight) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if insight.timestamp > 0 {
                Text(
                    Date(timeIntervalSince1970: insight.timestamp)
                        .formatted(date: .abbreviated, time: .shortened)
                )
                .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
            if !insight.reason.isEmpty {
                Text(insight.reason)
                    .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private var closeButton: some View {
        Button {
            Haptics.tap()
            if reduceMotion {
                dismiss()
            } else {
                isDismissing = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    dismiss()
                }
            }
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .frame(width: 44, height: 44)
                .background(DesignSystem.Colors.surface)
                .clipShape(Circle())
        }
        .accessibilityLabel("Close")
    }

    private func typeChip(_ insight: Insight) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: insight.type.iconName)
            Text(insight.type.displayName)
        }
        .fontStyle(DesignSystem.Typography.eyebrow, colorScheme: colorScheme)
        .foregroundStyle(DesignSystem.Colors.lime)
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.lime.opacity(0.14), in: Capsule())
    }

    private var currentInsight: Insight? {
        insights.indices.contains(index) ? insights[index] : nil
    }

    private var dismissScale: CGFloat {
        max(0.88, 1 - max(0, dragOffset.height) / 900)
    }

    private var dismissOpacity: Double {
        max(0.4, 1 - max(0, dragOffset.height) / 600)
    }

    private var viewerGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                if activeAxis == nil {
                    let dx = abs(value.translation.width)
                    let dy = abs(value.translation.height)
                    if dx < 15 && dy < 15 { return }
                    activeAxis = dx > dy ? .horizontal : .vertical
                }
                switch activeAxis {
                case .horizontal:
                    var x = value.translation.width
                    if (index == 0 && x > 0) || (index == insights.count - 1 && x < 0) {
                        x *= 0.3
                    }
                    dragOffset.width = x
                case .vertical:
                    dragOffset.height = value.translation.height
                case nil:
                    break
                }
            }
            .onEnded { value in
                switch activeAxis {
                case .horizontal:
                    let predicted = value.predictedEndTranslation.width
                    var target = index
                    if predicted < -80, index < insights.count - 1 {
                        target = index + 1
                    } else if predicted > 80, index > 0 {
                        target = index - 1
                    }
                    withAnimation(reduceMotion ? .easeOut(duration: 0.15) : Motion.smooth.animation) {
                        dragOffset = .zero
                        index = target
                    }
                case .vertical:
                    let predicted = value.predictedEndTranslation.height
                    if predicted > 200 || value.translation.height > 100 {
                        Haptics.cardRelease()
                        dismiss()
                    } else {
                        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : Motion.smooth.animation) {
                            dragOffset = .zero
                        }
                    }
                case nil:
                    break
                }
                activeAxis = nil
            }
    }
}