import SwiftUI

struct SavedReelCard: View {
    let reel: Reel
    let onTap: () -> Void
    let onUnsave: () -> Void
    var namespace: Namespace.ID?

    @Environment(\.isCardPressed) private var pressed
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                RemoteImage(url: reel.media.thumbnailUrl)
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                    .scaleEffect(pressed ? 1.02 : 1.0)
                    .animation(Motion.smooth.animation, value: pressed)
                    .ifLet(namespace) { view, ns in
                        view.matchedGeometryEffect(id: "thumb-\(reel.id)", in: ns)
                    }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: reel.source.iconName)
                            .font(.system(size: 10, weight: .bold))
                        Text(reel.source.displayName)
                            .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
                    }
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)

                    Text(reel.content.displayText)
                        .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if let entity = reel.entity {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 9, weight: .medium))
                            Text(entityDisplayName(entity))
                                .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                        }
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                    }

                    Spacer(minLength: 0)

                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(reel.metadata.createdAt.formatted(.relative(presentation: .named)))
                            .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
                            .foregroundStyle(DesignSystem.Colors.mutedMetadata)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(DesignSystem.Colors.tertiaryText)
                            .offset(x: pressed ? 4 : 0)
                            .animation(Motion.standard.animation, value: pressed)
                    }
                }
                .offset(y: pressed ? 2 : 0)
                .animation(Motion.standard.animation, value: pressed)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
            .shadowCard()
        }
        .buttonStyle(TactileCardStyle(scale: 0.98))
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Haptics.warning()
                onUnsave()
            } label: {
                Label("Remove", systemImage: "bookmark.slash")
            }
        }
        .accessibilityLabel(reel.content.displayText)
    }

    private func entityDisplayName(_ entity: Entity) -> String {
        entity.location.map { "\(entity.name) · \($0.displayString)" } ?? entity.name
    }
}