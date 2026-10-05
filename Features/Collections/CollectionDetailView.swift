import SwiftUI

struct CollectionDetailView: View {
    let collection: ReelGroup
    let reels: [Reel]
    let onReelSelected: (Reel) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var expandedIndex: Int? = nil
    @State private var hoverIndex: Int? = nil

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                headerBoard

                if reels.isEmpty {
                    emptySection
                } else {
                    pileBoard
                }

                metadataFooter
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, 140)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(collection.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
    }

    private var headerBoard: some View {
        ZStack(alignment: .bottomLeading) {
            if let first = reels.first {
                RemoteImage(url: first.media.thumbnailUrl)
                    .frame(height: 280)
                    .clipped()
            } else {
                gradientHeader
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text(collection.type.displayName.uppercased())
                        .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                    Spacer()
                    if reels.count > 0 {
                        Text("\(reels.count) \(reels.count == 1 ? "Reel" : "Reels")")
                            .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }

                Text(collection.name)
                    .fontStyle(DesignSystem.Typography.display, colorScheme: colorScheme)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                if let description = collection.description {
                    Text(description)
                        .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                        .foregroundStyle(.white.opacity(0.9))
                        .lineLimit(3)
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        .shadowFloating()
        .padding(.horizontal, -DesignSystem.Spacing.md)
    }

    private var gradientHeader: some View {
        let tint = groupTypeTint(collection.type)
        return ZStack {
            LinearGradient(
                colors: [tint.opacity(0.88), tint.opacity(0.45)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: groupTypeIcon(collection.type))
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.75))
                .rotationEffect(.degrees(-8))
        }
    }

    private var pileBoard: some View {
        ZStack {
            ForEach(reels.indices, id: \.self) { index in
                let isTop = index == reels.count - 1
                let depth = Double(reels.count - 1 - index)
                let isExpanded = expandedIndex == index

                pileCard(
                    reel: reels[index],
                    index: index,
                    isTop: isTop,
                    depth: depth,
                    isExpanded: isExpanded,
                    isHovered: hoverIndex == index
                )
            }
        }
    }

    @ViewBuilder
    private func pileCard(
        reel: Reel,
        index: Int,
        isTop: Bool,
        depth: Double,
        isExpanded: Bool,
        isHovered: Bool
    ) -> some View {
        let baseOffsetY = -22 * depth
        let baseRotation = depth * 1.8
        let scale = 1.0 - 0.035 * depth
        let expandedScale = isExpanded ? 1.02 : 1.0
        let hoverScale = isHovered ? 1.01 : 1.0
        let totalScale = scale * expandedScale * hoverScale

        ZStack {
            RemoteImage(url: reel.media.thumbnailUrl)
                .frame(width: 260, height: 340)
                .clipped()
                .scaleEffect(totalScale)
                .rotationEffect(.degrees(baseRotation + (isHovered ? (isEven ? 1.2 : -1.2) : 0)))
                .animation(Motion.smooth.animation, value: isHovered)
                .animation(Motion.hero.animation, value: isExpanded)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        .shadow(
            color: .black.opacity(isExpanded ? 0.22 : (isTop ? 0.18 : 0.12)),
            radius: isExpanded ? 32 : (isTop ? 24 : 14),
            y: isExpanded ? 18 : (isTop ? 12 : 8)
        )
        .offset(
            x: isHovered ? (isEven ? -12 : 12) : 0,
            y: baseOffsetY - (isExpanded ? 20 : 0) + (isHovered ? -8 : 0)
        )
        .zIndex(isTop ? 10 : Double(reels.count - index))
        .onHover { hovering in
            hoverIndex = hovering ? index : nil
        }
        .onTapGesture {
            Haptics.pileOpen()
            if reduceMotion {
                expandedIndex = isExpanded ? nil : index
            } else {
                withAnimation(Motion.hero.animation) {
                    expandedIndex = isExpanded ? nil : index
                }
            }
            onReelSelected(reel)
        }
        .accessibilityLabel(reel.content.displayText)
        .accessibilityAddTraits(isExpanded ? .isSelected : [])
    }

    private var isEven: Bool {
        reels.count % 2 == 0
    }

    private var emptySection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "photo.stack")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("This pile is empty")
                .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)
            Text("Save reels to fill this collection")
                .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxl)
    }

    private var metadataFooter: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("Last updated \(collection.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("Created \(collection.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.md)
    }

    private func groupTypeTint(_ type: GroupType) -> SwiftUI.Color {
        let colors: [GroupType: (light: String, dark: String)] = [
            .semantic: ("FF9F0A", "FFB340"),
            .location: ("0A84FF", "4DA6FF"),
            .topic: ("30D158", "64E67E"),
            .source: ("BF5AF2", "D48BFF"),
            .collection: ("64D2FF", "9AE0FF"),
        ]
        let pair = colors[type] ?? ("8E8E93", "AEAEB2")
        return colorScheme == .dark ? Color(hex: pair.dark) : Color(hex: pair.light)
    }

    private func groupTypeIcon(_ type: GroupType) -> String {
        switch type {
        case .semantic: return "sparkles"
        case .location: return "mappin.and.ellipse"
        case .topic: return "tag.fill"
        case .source: return "square.stack.3d.up"
        case .collection: return "folder.fill"
        default: return "folder.fill"
        }
    }
}