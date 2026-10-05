import SwiftUI

struct HomeView: View {
    let response: ReelScoutResponse
    let onReelSelected: (Reel) -> Void
    let onGroupSelected: (ReelGroup) -> Void
    let onSourceSelected: (Source) -> Void
    var onSeeAllForYou: (() -> Void)? = nil

    @State private var isRefreshing = false
    @State private var order: [String] = []
    @State private var dropZoneActive = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: DesignSystem.Spacing.xxl) {
                    if reels.isEmpty && !isInitialLoading {
                        emptyState
                    } else {
                        header
                            .staggeredEntrance(index: 0)

                        if let hero = reels.first {
                            ReelCard(reel: hero, style: .hero, onTap: { onReelSelected(hero) })
                                .staggeredEntrance(index: 1)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .scrollReveal()
                        }

                        // Drop Zone (lazy loaded)
                        if !reels.isEmpty {
                            DropZone(
                                onDrop: { reel in
                                    onReelSelected(reel)
                                },
                                isActive: dropZoneActive
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .staggeredEntrance(index: 2)
                        }

                        scoutingReport
                            .staggeredEntrance(index: 3)
                            .padding(.horizontal, DesignSystem.Spacing.md)

                        if orderedReels.count > 1 {
                            asymmetricCluster(Array(orderedReels.dropFirst()))
                                .staggeredEntrance(index: 4)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                        }

                        if orderedReels.count > 3 {
                            shelf.staggeredEntrance(index: 5)
                        }

                        if !response.groups.isEmpty {
                            collectionsStrip
                        }

                        if !response.sources.isEmpty {
                            sourceStrip
                        }

                        footerCopy
                    }
                }
                .padding(.top, DesignSystem.Spacing.sm)
                .padding(.bottom, 140)
            }
            .background(DesignSystem.Colors.background)
            .refreshable {
                await scout()
            }
            .navigationTitle("ReelScout")
            .navigationBarTitleDisplayMode(.inline)
            .scrollIndicators(.hidden)
            .accessibilityIdentifier("homeScrollView")
        }
    }

    private var isInitialLoading: Bool {
        response.reels.isEmpty && response.groups.isEmpty && isRefreshing
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: DesignSystem.Spacing.sm) {
                Text("Your discoveries")
                    .fontStyle(DesignSystem.Typography.display, colorScheme: colorScheme)
                Spacer()
                scoutingDot
            }
            Text(scopingLine)
                .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private var scopingLine: String {
        let count = orderedReels.count
        guard count > 0 else { return "Scouting your shares" }
        return "Scouting your shares · \(count) \(count == 1 ? "find" : "finds") waiting"
    }

    private var scoutingDot: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(DesignSystem.Colors.lime)
                .frame(width: 7, height: 7)
                .shadow(color: DesignSystem.Colors.lime.opacity(0.7), radius: 5)
                .scaleEffect(isRefreshing ? 1.5 : 1)
                .opacity(isRefreshing ? 0.5 : 1)
                .animation(
                    isRefreshing ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true) : Motion.smooth.animation,
                    value: isRefreshing
                )
            Text(isRefreshing ? "Scouting" : "Watching")
                .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .contentTransition(.opacity)
                .animation(Motion.smooth.animation, value: isRefreshing)
        }
        .accessibilityLabel(isRefreshing ? "Scouting" : "Watching")
    }

    // MARK: Big numbers — one moment of scale, then compact

    private var scoutingReport: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.lg) {
            bigStat(value: orderedReels.count, caption: "new finds", tint: DesignSystem.Colors.lime)
            bigStat(value: response.groups.count, caption: "collections", tint: DesignSystem.Colors.coral)
            bigStat(value: clueCount, caption: "clues", tint: DesignSystem.Colors.lavender)
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        .shadowCard()
    }

    private var clueCount: Int {
        orderedReels.reduce(0) { $0 + $1.insights.count }
    }

    private func bigStat(value: Int, caption: String, tint: SwiftUI.Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("\(max(value, 0))")
                .fontStyle(DesignSystem.Typography.hero, colorScheme: colorScheme)
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                .animation(Motion.smooth.animation, value: value)
            Text(caption.uppercased())
                .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Asymmetric cluster

    private func asymmetricCluster(_ items: [Reel]) -> some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
            ReelCard(reel: items[0], style: .feature, onTap: { onReelSelected(items[0]) })
                .frame(maxWidth: .infinity)
            if items.count > 1 {
                ReelCard(reel: items[1], style: .feature, onTap: { onReelSelected(items[1]) })
                    .frame(maxWidth: .infinity)
                    .padding(.top, 34)
            }
        }
    }

    // MARK: Shelf

    private var shelf: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader(
                title: "More worth a look",
                action: onSeeAllForYou == nil ? nil : "See all",
                onAction: onSeeAllForYou
            )
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    ForEach(Array(orderedReels.dropFirst().enumerated()), id: \.element.id) { index, reel in
                        ReelCard(reel: reel, style: .shelf, onTap: { onReelSelected(reel) })
                            .frame(width: 176)
                            .scrollRevealHorizontal()
                            .staggeredEntrance(index: index)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    // MARK: Collections — overlapping boards

    private var collectionsStrip: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader(title: "Your collections", action: "All") {
                onGroupSelected(response.groups[0])
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                    ForEach(Array(response.groups.enumerated()), id: \.element.id) { index, group in
                        CollectionCard(
                            group: group,
                            reelCount: group.reelIds.count,
                            previews: previews(for: group),
                            onTap: { onGroupSelected(group) }
                        )
                        .frame(width: 214)
                        .rotationEffect(.degrees(index.isMultiple(of: 2) ? -0.7 : 0.7))
                        .staggeredEntrance(index: index + 2)
                        .scrollRevealHorizontal()
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, 6)
            }
        }
    }

    // MARK: Sources

    private var sourceStrip: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            sectionHeader(title: "Scouting from", action: nil)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(response.sources) { source in
                        Button {
                            Haptics.selection()
                            onSourceSelected(source)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: source.type.iconName)
                                    .font(.system(size: 13, weight: .semibold))
                                Text(source.name)
                                    .fontStyle(DesignSystem.Typography.callout, colorScheme: colorScheme)
                            }
                            .foregroundStyle(DesignSystem.Colors.primaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(DesignSystem.Colors.surface, in: Capsule())
                            .overlay(Capsule().strokeBorder(DesignSystem.Colors.subtleBorder, lineWidth: 0.5))
                        }
                        .buttonStyle(TactileCardStyle(scale: 0.97))
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    // MARK: Section header

    private func sectionHeader(title: String, action: String?, onAction: (() -> Void)? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)
            Spacer()
            if let action {
                Button(action: {
                    Haptics.selection()
                    onAction?()
                }) {
                    Text(action)
                        .fontStyle(DesignSystem.Typography.buttonSmall, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.lime)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }

    private var footerCopy: some View {
        VStack(spacing: 6) {
            Text("Found something?")
                .fontStyle(DesignSystem.Typography.bodyEmphasized, colorScheme: colorScheme)
            Text("Share a reel with ReelScout and it figures out what's worth knowing.")
                .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DesignSystem.Spacing.xxl)
        .padding(.top, DesignSystem.Spacing.md)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            ZStack {
                Circle()
                    .strokeBorder(DesignSystem.Colors.subtleBorder, style: StrokeStyle(lineWidth: 2, dash: [6, 8]))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(
                        isRefreshing ? .linear(duration: 2.4).repeatForever(autoreverses: false) : Motion.smooth.animation,
                        value: isRefreshing
                    )
                Image(systemName: "binoculars.fill")
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(DesignSystem.Colors.lime)
                    .scaleEffect(isRefreshing ? 1.1 : 1)
                    .animation(isRefreshing ? .spring(response: 0.5, dampingFraction: 0.6).repeatForever(autoreverses: true) : Motion.smooth.animation, value: isRefreshing)
            }
            Text("Your curious little world is empty.")
                .fontStyle(DesignSystem.Typography.editorialTitle, colorScheme: colorScheme)
                .multilineTextAlignment(.center)
            Text("Share something worth remembering.\nThen watch ReelScout find what's hidden.")
                .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xxl)
            Button {
                Task { await scout() }
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
        .padding(.top, 120)
        .accessibilityIdentifier("homeEmptyState")
    }

    // MARK: Data helpers

    private var reels: [Reel] { response.reels }

    private var orderedReels: [Reel] {
        guard !order.isEmpty else { return reels }
        let byId = Dictionary(uniqueKeysWithValues: reels.map { ($0.id, $0) })
        let ordered = order.compactMap { byId[$0] }
        let missing = reels.filter { !order.contains($0.id) }
        return ordered + missing
    }

    private func previews(for group: ReelGroup) -> [String] {
        group.reelIds.compactMap { id in
            reels.first { $0.id == id }?.media.thumbnailUrl
        }
    }

    private func scout() async {
        isRefreshing = true
        Haptics.selection()
        try? await Task.sleep(nanoseconds: 550_000_000)
        if reels.count > 1 {
            var next = reels.map(\.id)
            next.shuffle()
            order = next
        }
        isRefreshing = false
        Haptics.success()
    }
}

extension Int {
    var isMultiple: (Int) -> Bool {
        { $0 % self == 0 }
    }
}