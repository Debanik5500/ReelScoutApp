import SwiftUI

struct SourceDetailView: View {
    let source: Source
    let reels: [Reel]
    let onReelSelected: (Reel) -> Void

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                headerBoard

                if reels.isEmpty {
                    emptySection
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 160), spacing: DesignSystem.Spacing.md)],
                        spacing: DesignSystem.Spacing.md
                    ) {
                        ForEach(reels) { reel in
                            ReelCard(reel: reel, style: .shelf, onTap: { onReelSelected(reel) })
                                .frame(width: 176)
                                .staggeredEntrance(index: 0)
                                .scrollReveal()
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }

                metadataFooter
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, 140)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle(source.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollIndicators(.hidden)
    }

    private var headerBoard: some View {
        ZStack(alignment: .bottomLeading) {
            gradientHeader

            LinearGradient(
                colors: [.clear, .black.opacity(0.15), .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text(source.type.displayName.uppercased())
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

                Text(source.name)
                    .fontStyle(DesignSystem.Typography.display, colorScheme: colorScheme)
                    .foregroundStyle(.white)
                    .lineLimit(2)
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        .shadowFloating()
        .padding(.horizontal, -DesignSystem.Spacing.md)
    }

    private var gradientHeader: some View {
        ZStack {
            LinearGradient(
                colors: [
                    sourceTypeTint(source.type).opacity(0.88),
                    sourceTypeTint(source.type).opacity(0.45)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: source.type.iconName)
                .font(.system(size: 60, weight: .light))
                .foregroundStyle(.white.opacity(0.75))
                .rotationEffect(.degrees(-8))
        }
    }

    private var emptySection: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "photo.stack")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
            Text("No reels from this source yet")
                .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)
            Text("Share a Reel from \(source.name) to see it here")
                .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.xxxl)
    }

    private var metadataFooter: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Text("\(source.count) Reels")
                .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, DesignSystem.Spacing.md)
    }

    private func sourceTypeTint(_ type: SourceType) -> SwiftUI.Color {
        switch type {
        case .instagram: return DesignSystem.Colors.instagram
        case .tiktok: return DesignSystem.Colors.tiktok
        case .youtube: return DesignSystem.Colors.youtube
        case .whatsapp: return DesignSystem.Colors.instagram
        case .gallery: return DesignSystem.Colors.lavender
        case .safari: return DesignSystem.Colors.lime
        case .upload: return DesignSystem.Colors.coral
        case .other: return DesignSystem.Colors.tertiaryText
        case .unknown: return DesignSystem.Colors.tertiaryText
        }
    }
}