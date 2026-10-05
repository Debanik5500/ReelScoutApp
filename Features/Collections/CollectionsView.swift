import SwiftUI

struct CollectionsView: View {
    let groups: [ReelGroup]
    let reels: [Reel]
    let onGroupSelected: (ReelGroup) -> Void

    @State private var isRefreshing = false
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                if groups.isEmpty && !isRefreshing {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            headerSection

                            LazyVGrid(
                                columns: [GridItem(.adaptive(minimum: 200), spacing: DesignSystem.Spacing.md)],
                                spacing: DesignSystem.Spacing.md
                            ) {
                                ForEach(groups) { group in
                                    CollectionCard(
                                        group: group,
                                        reelCount: group.reelIds.count,
                                        previews: previews(for: group),
                                        onTap: { onGroupSelected(group) }
                                    )
                                    .staggeredEntrance(index: 0)
                                    .scrollReveal()
                                }
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.bottom, 100)
                        }
                        .padding(.top, DesignSystem.Spacing.sm)
                    }
                    .refreshable { await refresh() }
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.large)
            .scrollIndicators(.hidden)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(groups.count) \(groups.count == 1 ? "collection" : "collections")")
                    .fontStyle(DesignSystem.Typography.hero, colorScheme: colorScheme)
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(DesignSystem.Colors.lime)
                }
            }
            Text("Your visual piles")
                .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.top, DesignSystem.Spacing.sm)
    }

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .strokeBorder(DesignSystem.Colors.subtleBorder, style: StrokeStyle(lineWidth: 2, dash: [6, 8]))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                Image(systemName: "folder.fill")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(DesignSystem.Colors.lime)
            }
            Text("No collections yet.")
                .fontStyle(DesignSystem.Typography.editorialTitle, colorScheme: colorScheme)
                .multilineTextAlignment(.center)
            Text("Save reels and ReelScout will\norganize them into visual piles.")
                .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 140)
    }

    private func previews(for group: ReelGroup) -> [String] {
        group.reelIds.compactMap { id in
            reels.first { $0.id == id }?.media.thumbnailUrl
        }
    }

    private func refresh() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
    }
}