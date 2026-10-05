import SwiftUI

struct DiscoveryResultView: View {
    let reel: Reel
    let isSaved: Bool
    var groupNames: [String] = []
    var relatedReels: [Reel] = []
    let onSave: () -> Void
    let onShare: () -> Void
    let onOpenURL: (String) -> Void
    var onReelSelected: ((Reel) -> Void)? = nil

    @EnvironmentObject private var appState: AppState
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    @State private var revealStage = 0
    @State private var saveBurstCount = 0
    @State private var saveButtonFrame = CGRect.zero
    @State private var localIsSaved = false

    private var savedNow: Bool { localIsSaved || isSaved }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                reelHeader
                if !reel.insights.isEmpty {
                    insightsSection
                        .staggeredEntrance(index: 2, enabled: revealStage >= 2)
                }
                if !reel.actions.isEmpty {
                    actionsSection
                        .staggeredEntrance(index: 3, enabled: revealStage >= 3)
                }
                if !reel.attributes.isEmpty && revealStage >= 3 {
                    attributesSection
                }
                if reel.entity != nil && revealStage >= 3 {
                    entitySection
                }
                if !groupNames.isEmpty {
                    savedInSection
                }
                if !relatedReels.isEmpty {
                    relatedSection
                }
                metadataFooter
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("Discovery")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var reelHeader: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            heroMedia

            if let title = reel.content.title {
                Text(title)
                    .fontStyle(DesignSystem.Typography.editorialTitle, colorScheme: colorScheme)
            } else if reel.entity == nil {
                Text(reel.content.displayText)
                    .fontStyle(DesignSystem.Typography.editorialTitle, colorScheme: colorScheme)
            }

            if let description = reel.content.summary ?? reel.content.description,
               revealStage >= 3 {
                Text(description)
                    .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                sourceBadge
                Spacer()
                if let duration = reel.media.durationSeconds {
                    Text(duration.formattedDuration)
                        .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .contentTransition(.opacity)
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private var heroMedia: some View {
        ZStack(alignment: .bottomLeading) {
            RemoteImage(url: reel.media.thumbnailUrl)
                .frame(height: 330)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.06), .black.opacity(0.74)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                HStack {
                    sourceBadge
                    Spacer()
                    if let duration = reel.media.durationSeconds {
                        Text(duration.formattedDuration)
                            .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                }

                Spacer(minLength: 12)

                if let entity = reel.entity {
                    Text(revealStage == 0 ? "What is this?" : entity.name)
                        .fontStyle(
                            revealStage == 0
                            ? DesignSystem.Typography.hero
                            : DesignSystem.Typography.display,
                            colorScheme: colorScheme
                        )
                        .foregroundStyle(.white)
                        .contentTransition(.opacity)
                        .animation(reduceMotion ? .linear(duration: 0.1) : Motion.smooth.animation, value: revealStage)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)

                    if revealStage >= 2, let location = entity.location?.displayString {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .fontStyle(DesignSystem.Typography.eyebrow, colorScheme: colorScheme)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(.ultraThinMaterial, in: Capsule())
                            .transition(.scale(scale: 0.7, anchor: .leading).combined(with: .opacity))
                    }
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(height: 330)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
        .shadow(
            color: .black.opacity(0.2),
            radius: 22,
            y: 12
        )
        .padding(.horizontal, -DesignSystem.Spacing.lg)
        .task {
            withAnimation(.easeOut(duration: 0.35)) { revealStage = max(revealStage, 1) }
            try? await Task.sleep(nanoseconds: 700_000_000)
            withAnimation(Motion.smooth.animation) { revealStage = max(revealStage, 2) }
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(Motion.smooth.animation) { revealStage = max(revealStage, 3) }
        }
    }

    private var sourceBadge: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: reel.source.iconName)
                .font(.system(size: 11, weight: .bold))
            Text(reel.source.displayName)
                .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(
            DesignSystem.Colors.surface.opacity(0.9),
            in: Capsule()
        )
        .foregroundStyle(.white)
    }

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(reel.insights.count) things worth knowing")
                    .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)
                    .contentTransition(.numericText())

                Text("Drag the frames. Tilt them. They respond.")
                    .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
            }

            if !reel.insights.isEmpty {
                InsightFrameStack(insights: reel.insights)
            }

            if let reason = reel.insights.first?.reason {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("From the Reel")
                        .fontStyle(DesignSystem.Typography.eyebrow, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .textCase(.uppercase)
                    Text(reason)
                        .fontStyle(DesignSystem.Typography.callout, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                }
                .padding(DesignSystem.Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(DesignSystem.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
            }
        }
    }

    private var savedInSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Saved in")
                .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)

            FlowLayout(spacing: DesignSystem.Spacing.sm) {
                ForEach(groupNames, id: \.self) { name in
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "folder")
                            .font(.system(size: 11, weight: .medium))
                        Text(name)
                            .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.lime.opacity(0.14))
                    .foregroundStyle(DesignSystem.Colors.lime)
                    .clipShape(Capsule())
                }
            }
        }
    }

    private var relatedSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Related discoveries")
                .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)

            VStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(relatedReels) { related in
                    Button {
                        Haptics.tap()
                        onReelSelected?(related)
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous)
                                .fill(DesignSystem.Colors.surface)
                                .frame(width: 44, height: 60)
                                .overlay {
                                    Image(systemName: "play.circle")
                                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                                }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(related.content.displayText)
                                    .fontStyle(DesignSystem.Typography.callout, colorScheme: colorScheme)
                                    .foregroundStyle(DesignSystem.Colors.primaryText)
                                    .lineLimit(1)
                                Text(related.source.displayName)
                                    .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                                    .foregroundStyle(DesignSystem.Colors.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                        }
                        .padding(DesignSystem.Spacing.sm)
                        .background(DesignSystem.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var attributesSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Details")
                .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)

            VStack(spacing: 0) {
                ForEach(reel.attributes) { attribute in
                    AttributeRow(attribute: attribute)
                    if attribute.id != reel.attributes.last?.id {
                        Divider()
                            .padding(.leading, DesignSystem.Spacing.lg)
                    }
                }
            }
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
        }
    }

    private var entitySection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Detected")
                .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)

            if let entity = reel.entity {
                FlowLayout(spacing: DesignSystem.Spacing.sm) {
                    EntityChip(entity: entity, colorScheme: colorScheme)
                }
            }
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("Actions")
                .fontStyle(DesignSystem.Typography.eyebrow, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
                .textCase(.uppercase)

            ActionButtons(
                actions: reel.actions,
                onSave: handleSave,
                onShare: onShare,
                onOpenURL: onOpenURL,
                isSaved: savedNow
            )
            .saveBurst(trigger: saveBurstCount)
            .background {
                GeometryReader { geo in
                    Color.clear
                        .preference(key: SaveActionFrameKey.self, value: geo.frame(in: .global))
                }
            }
            .onPreferenceChange(SaveActionFrameKey.self) { saveButtonFrame = $0 }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
    }

    private func handleSave() {
        withAnimation(Motion.quick.animation) { localIsSaved.toggle() }
        onSave()
        saveBurstCount += 1
        Haptics.bookmark()
        let origin = CGPoint(x: saveButtonFrame.midX, y: saveButtonFrame.midY)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            appState.flySaveToSavedTab(from: origin)
        }
    }

    private var metadataFooter: some View {
        HStack {
            if let confidence = reel.metadata.confidence {
                Label {
                    Text("\(Int(min(max(confidence, 0), 1) * 100))% confidence")
                        .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                } icon: {
                    Image(systemName: "checkmark.shield")
                        .foregroundStyle(confidenceColor(confidence))
                }
            } else {
                Label {
                    Text("Analyzed")
                        .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                } icon: {
                    Image(systemName: "checkmark.shield")
                        .foregroundStyle(DesignSystem.Colors.lime)
                }
            }
            Spacer()
            Text(reel.metadata.createdAt.formatted(date: .abbreviated, time: .shortened))
                .fontStyle(DesignSystem.Typography.footnote, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.tertiaryText)
        }
        .padding(.top, DesignSystem.Spacing.sm)
    }

    private func confidenceColor(_ confidence: Double) -> SwiftUI.Color {
        if confidence >= 0.9 { return DesignSystem.Colors.lime }
        if confidence >= 0.7 { return DesignSystem.Colors.coral }
        return DesignSystem.Colors.coral.opacity(0.7)
    }
}

struct EntityChip: View {
    let entity: Entity
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: entity.type.iconName)
                .font(.system(size: 10, weight: .medium))
            Text(entity.name)
                .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
            if entity.verified == true {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(DesignSystem.Colors.lime)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .background(DesignSystem.Colors.surface)
        .clipShape(Capsule())
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: LayoutSubviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

extension Int {
    var formattedDuration: String {
        let minutes = self / 60
        let seconds = self % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SaveActionFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}