import SwiftUI

struct SavedView: View {
    let reels: [Reel]
    let onReelSelected: (Reel) -> Void
    let onUnsave: (String) -> Void

    @State private var isRefreshing = false
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.background.ignoresSafeArea()

                if filteredReels.isEmpty && !isRefreshing {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            headerSection

                            if !searchText.isEmpty || !reels.isEmpty {
                                LazyVGrid(
                                    columns: [GridItem(.adaptive(minimum: 160), spacing: DesignSystem.Spacing.md)],
                                    spacing: DesignSystem.Spacing.md
                                ) {
                                    ForEach(filteredReels) { reel in
                                        SavedReelCard(
                                            reel: reel,
                                            onTap: { onReelSelected(reel) },
                                            onUnsave: { onUnsave(reel.id) }
                                        )
                                        .staggeredEntrance(index: 0)
                                        .scrollReveal()
                                    }
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                        }
                        .padding(.bottom, 140)
                    }
                    .refreshable {
                        await refresh()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search saved discoveries")
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.large)
            .scrollIndicators(.hidden)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(reels.count) \(reels.count == 1 ? "find" : "finds")")
                    .fontStyle(DesignSystem.Typography.hero, colorScheme: colorScheme)
                Spacer()
                if isRefreshing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .tint(DesignSystem.Colors.lime)
                }
            }
            Text("Your visual archive")
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
                    .animation(isRefreshing ? .linear(duration: 2.4).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                Image(systemName: "bookmark")
                    .font(.system(size: 30, weight: .light))
                    .foregroundStyle(DesignSystem.Colors.lime)
            }
            Text("Your archive is empty.")
                .fontStyle(DesignSystem.Typography.editorialTitle, colorScheme: colorScheme)
                .multilineTextAlignment(.center)
            Text("Share a Reel with ReelScout.\nIt finds what's worth remembering.")
                .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
            Button {
                Task { await refresh() }
            } label: {
                Text(isRefreshing ? "Scouting…" : "Start scouting")
                    .fontStyle(DesignSystem.Typography.button, colorScheme: colorScheme)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(DesignSystem.Colors.lime, in: Capsule())
            }
            .buttonStyle(TactileCardStyle(scale: 0.97))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 140)
    }

    private var filteredReels: [Reel] {
        if searchText.isEmpty {
            return reels
        }
        return reels.filter { reel in
            let text = "\(reel.content.title ?? "") \(reel.content.summary ?? "") \(reel.content.description ?? "") \(reel.entity?.name ?? "")"
            return text.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func refresh() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 500_000_000)
        isRefreshing = false
    }
}