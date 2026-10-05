import SwiftUI

struct SourcesView: View {
    let sources: [Source]
    let onSourceSelected: (Source) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            if sources.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.md) {
                    Text("Everything you send, sorted by where it came from.")
                        .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, DesignSystem.Spacing.xs)

                    ForEach(Array(sources.enumerated()), id: \.element.id) { index, source in
                        SourceListRow(source: source, onTap: { onSourceSelected(source) })
                            .staggeredEntrance(index: index, enabled: true)
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Sources")
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "square.stack.3d.up")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("No sources yet")
                .fontStyle(DesignSystem.Typography.title3, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.primaryText)
            Text("Share something from Instagram, TikTok, or YouTube — the source figures itself out.")
                .fontStyle(DesignSystem.Typography.subheadline, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 110)
        .padding(DesignSystem.Spacing.xl)
    }
}

struct SourceListRow: View {
    let source: Source
    let onTap: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(SwiftUI.Color(hex: source.type.colorHex).opacity(0.16))
                        .frame(width: 48, height: 48)
                    Image(systemName: source.type.iconName)
                        .font(.title3)
                        .foregroundStyle(SwiftUI.Color(hex: source.type.colorHex))
                }

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(source.name)
                        .fontStyle(DesignSystem.Typography.headline, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                    Text("\(source.count) reels")
                        .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                    .strokeBorder(DesignSystem.Colors.subtleBorder, lineWidth: 1)
            )
        }
        .buttonStyle(TactileCardStyle(scale: 0.98))
    }
}