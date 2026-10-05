import SwiftUI

struct CollectionCard: View {
    let group: ReelGroup
    let reelCount: Int
    var previews: [String] = []
    let onTap: () -> Void

    @Environment(\.isCardPressed) private var pressed
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            Haptics.pileOpen()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                board
                    .frame(height: 156)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                            .stroke(DesignSystem.Colors.subtleBorder, lineWidth: 0.5)
                    )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(group.name)
                        .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .lineLimit(1)

                    Text(subtitle)
                        .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.mutedMetadata)
                        .lineLimit(1)
                }
                .padding(.horizontal, 2)
                .offset(y: pressed ? 2 : 0)
                .animation(Motion.standard.animation, value: pressed)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
            .shadowCard()
        }
        .buttonStyle(TactileCardStyle(scale: 0.97))
        .accessibilityLabel(group.name)
    }

    private var subtitle: String {
        let unit = reelCount == 1 ? "Reel" : "Reels"
        switch group.type {
        case .semantic: return "\(reelCount) \(unit) · Discovered"
        case .location: return "\(reelCount) \(unit) · Mapped"
        case .topic: return "\(reelCount) \(unit) · Pinned"
        case .source: return "\(reelCount) \(unit) · Source"
        case .collection: return "\(reelCount) \(unit) · Collection"
        default: return "\(reelCount) \(unit)"
        }
    }

    // MARK: Board Compositions

    @ViewBuilder
    private var board: some View {
        switch previews.count {
        case 0:
            typographicBoard
        case 1:
            heroBoard
        case 2:
            splitBoard
        case 3:
            stackBoard
        default:
            collageBoard
        }
    }

    private var typographicBoard: some View {
        let tint = groupTypeTint(group.type, scheme: colorScheme)
        return ZStack {
            LinearGradient(
                colors: [tint.opacity(0.88), tint.opacity(0.52)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: groupTypeIcon(group.type))
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                        .rotationEffect(.degrees(-6))
                        .offset(x: -8, y: 8)
                }
                Spacer()
            }
        }
    }

    private var heroBoard: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: previews.first)
                .scaleEffect(pressed ? 1.03 : 1.0)
                .animation(Motion.smooth.animation, value: pressed)

            LinearGradient(
                colors: [.clear, .black.opacity(0.15), .black.opacity(0.68)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(group.type.displayName.uppercased())
                    .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.ultraThinMaterial, in: Capsule())

                Text(group.name)
                    .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 2)
            }
            .padding(DesignSystem.Spacing.md)
            .offset(y: pressed ? 4 : 0)
            .animation(Motion.standard.animation, value: pressed)
        }
    }

    private var splitBoard: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            ForEach(0..<2, id: \.self) { index in
                RemoteImage(url: safePreview(index))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                    .scaleEffect(pressed ? 0.98 : 1.0)
                    .animation(Motion.smooth.animation, value: pressed)
            }
        }
    }

    private var stackBoard: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let offset = stackOffset(index)
                let rotation = stackRotation(index)
                let scale = stackScale(index)
                let zIndex = Double(2 - index)

                RemoteImage(url: safePreview(index))
                    .scaleEffect(scale * (pressed ? 0.96 : 1.0))
                    .rotationEffect(.degrees(rotation))
                    .offset(offset)
                    .shadow(
                        color: .black.opacity(pressed ? 0.1 : 0.2),
                        radius: pressed ? 4 : (index == 2 ? 12 : 8),
                        y: pressed ? 2 : (index == 2 ? 6 : 4)
                    )
                    .animation(Motion.standard.animation, value: pressed)
                    .zIndex(zIndex)
            }
        }
        .clipped()
    }

    private var collageBoard: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(0..<2, id: \.self) { index in
                    RemoteImage(url: safePreview(index))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                }
            }
            HStack(spacing: DesignSystem.Spacing.xs) {
                ForEach(2..<4, id: \.self) { index in
                    RemoteImage(url: safePreview(index))
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                }
            }
        }
        .clipped()
    }

    private func stackOffset(_ index: Int) -> CGSize {
        let offsets: [(CGFloat, CGFloat)] = [
            (-28, 8),
            (4, -4),
            (32, 10)
        ]
        return CGSize(width: offsets[index].0, height: offsets[index].1)
    }

    private func stackRotation(_ index: Int) -> Double {
        [-4.5, 3.5, -1.2][index]
    }

    private func stackScale(_ index: Int) -> CGFloat {
        [0.82, 0.86, 0.92][index]
    }

    private func safePreview(_ index: Int) -> String? {
        previews.indices.contains(index) ? previews[index] : nil
    }

    private func groupTypeTint(_ type: GroupType, scheme: ColorScheme) -> SwiftUI.Color {
        let colors: [GroupType: (light: String, dark: String)] = [
            .semantic: ("FF9F0A", "FFB340"),
            .location: ("0A84FF", "4DA6FF"),
            .topic: ("30D158", "64E67E"),
            .source: ("BF5AF2", "D48BFF"),
            .collection: ("64D2FF", "9AE0FF"),
        ]
        let pair = colors[type] ?? ("8E8E93", "AEAEB2")
        return scheme == .dark ? Color(hex: pair.dark) : Color(hex: pair.light)
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