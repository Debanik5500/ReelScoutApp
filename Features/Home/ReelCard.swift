import SwiftUI

enum ReelCardStyle {
    case hero
    case feature
    case shelf
    case compact
}

struct ReelCard: View {
    let reel: Reel
    var style: ReelCardStyle = .shelf
    let onTap: () -> Void

    @Environment(\.isCardPressed) private var pressed
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            Haptics.cardPress()
            onTap()
        } label: {
            switch style {
            case .hero: heroCard
            case .feature: featureCard
            case .shelf: shelfCard
            case .compact: compactCard
            }
        }
        .buttonStyle(TactileCardStyle(scale: style == .hero ? 0.985 : 0.96))
        .shadowCard()
    }

    // MARK: Hero

    private var heroCard: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: reel.media.thumbnailUrl)
                .frame(height: 340)
                .clipped()
                .scaleEffect(pressed ? 1.02 : 1.0)
                .animation(Motion.smooth.animation, value: pressed)

            LinearGradient(
                colors: [.clear, .black.opacity(0.12), .black.opacity(0.72)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                sourceBadge

                Text(reel.content.displayText)
                    .fontStyle(DesignSystem.Typography.hero, colorScheme: colorScheme)
                    .foregroundStyle(.white)
                    .lineLimit(3)
                    .minimumScaleFactor(0.88)
                    .shadow(color: .black.opacity(0.3), radius: 12, y: 4)

                if let entity = reel.entity {
                    entityPill(entity)
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .offset(y: pressed ? 4 : 0)
            .animation(Motion.standard.animation, value: pressed)
        }
        .frame(height: 340)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xxl, style: .continuous))
        .shadowFloating()
        .accessibilityLabel(reel.content.displayText)
    }

    private var sourceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: reel.source.iconName)
                .font(.system(size: 10, weight: .bold))
            Text(reel.source.displayName.uppercased())
                .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                .foregroundStyle(.white.opacity(0.92))
            Spacer()
            if reel.media.durationSeconds ?? 0 > 0 {
                Text(durationText)
                    .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
    }

    // MARK: Feature (tall)

    private var featureCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                RemoteImage(url: reel.media.thumbnailUrl)
                    .frame(height: 210)
                    .clipped()
                    .scaleEffect(pressed ? 1.015 : 1.0)
                    .animation(Motion.smooth.animation, value: pressed)

                if reel.media.durationSeconds ?? 0 > 0 {
                    Text(durationText)
                        .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(12)
                }
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignSystem.Radius.xl,
                    topTrailingRadius: DesignSystem.Radius.xl
                )
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(reel.content.displayText)
                    .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let entity = reel.entity {
                    Text(entityDisplayName(entity))
                        .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DesignSystem.Colors.surface)
            .offset(y: pressed ? 2 : 0)
            .animation(Motion.standard.animation, value: pressed)
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        .shadowCard()
        .accessibilityLabel(reel.content.displayText)
    }

    // MARK: Shelf

    private var shelfCard: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            ZStack(alignment: .bottomLeading) {
                RemoteImage(url: reel.media.thumbnailUrl)
                    .frame(height: 140)
                    .clipped()
                    .scaleEffect(pressed ? 1.02 : 1.0)
                    .animation(Motion.smooth.animation, value: pressed)

                if let entity = reel.entity {
                    entityPill(entity)
                        .padding(DesignSystem.Spacing.sm)
                        .opacity(pressed ? 0 : 1)
                        .offset(y: pressed ? 8 : 0)
                        .animation(Motion.quick.animation, value: pressed)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))

            Text(reel.content.displayText)
                .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            HStack(spacing: DesignSystem.Spacing.xs) {
                sourceBadgeSmall
                Text(reel.metadata.createdAt.formatted(.relative(presentation: .named)))
                    .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.mutedMetadata)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        .shadowCard()
        .accessibilityLabel(reel.content.displayText)
    }

    private var sourceBadgeSmall: some View {
        HStack(spacing: 4) {
            Image(systemName: reel.source.iconName)
                .font(.system(size: 9, weight: .bold))
            Text(reel.source.displayName)
                .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
        }
        .foregroundStyle(DesignSystem.Colors.tertiaryText)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            DesignSystem.Colors.subtleBorder,
            in: Capsule()
        )
    }

    // MARK: Compact row

    private var compactCard: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            RemoteImage(url: reel.media.thumbnailUrl)
                .frame(width: 84, height: 84)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
                .scaleEffect(pressed ? 1.015 : 1.0)
                .animation(Motion.smooth.animation, value: pressed)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(reel.content.displayText)
                    .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.primaryText)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Text(reel.source.displayName)
                    if let entity = reel.entity {
                        Text("·")
                        Text(entityDisplayName(entity))
                    }
                }
                .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .lineLimit(1)
            }
            .offset(y: pressed ? 2 : 0)
            .animation(Motion.standard.animation, value: pressed)

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .offset(x: pressed ? 4 : 0)
                .animation(Motion.standard.animation, value: pressed)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        .shadowCard()
        .accessibilityLabel(reel.content.displayText)
    }

    // MARK: Pieces

    private func entityPill(_ entity: Entity) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 11, weight: .medium))
            Text(entityDisplayName(entity))
                .fontStyle(DesignSystem.Typography.eyebrow, colorScheme: colorScheme)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(.ultraThinMaterial.opacity(0.9), in: Capsule())
    }

    private var durationText: String {
        let total = reel.media.durationSeconds ?? 0
        let mins = total / 60
        let secs = total % 60
        return String(format: "%d:%02d", mins, secs)
    }

    private func entityDisplayName(_ entity: Entity) -> String {
        entity.location.map { "\(entity.name) · \($0.displayString)" } ?? entity.name
    }
}