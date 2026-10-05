import SwiftUI

struct ProcessingView: View {
    @Binding var state: ProcessingState
    let onComplete: () -> Void
    let onRetry: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                // Stage copy
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(headline)
                        .fontStyle(DesignSystem.Typography.hero, colorScheme: colorScheme)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(Motion.smooth.animation, value: state.stage)

                    Text(subline)
                        .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(Motion.smooth.animation, value: state.stage)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                }
                .padding(.bottom, DesignSystem.Spacing.xl)

                // Visual core
                ZStack {
                    // Background atmosphere
                    if state.stage == .watching || state.stage == .identifying {
                        scanAtmosphere
                    }

                    if state.stage == .listening {
                        listeningAtmosphere
                    }

                    if state.stage == .lookingUp || state.stage == .enriching {
                        orbitAtmosphere
                    }

                    // Reel preview at center
                    reelPreview

                    // Completed overlay
                    if state.stage == .completed {
                        completedOverlay
                            .transition(.scale(scale: 0.9).combined(with: .opacity))
                    }
                }
                .frame(height: 420)
                .animation(Motion.cinematic.animation, value: state.stage)

                // Progress line
                VStack(spacing: DesignSystem.Spacing.md) {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        ForEach(ProcessingStage.allCases, id: \.self) { stage in
                            ProgressPip(
                                stage: stage,
                                current: state.stage,
                                progress: state.progress,
                                reduceMotion: reduceMotion
                            )
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)

                    // Message line
                    Text(state.message)
                        .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.mutedMetadata)
                        .multilineTextAlignment(.center)
                        .contentTransition(.opacity)
                        .animation(Motion.standard.animation, value: state.message)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                }
                .padding(.top, DesignSystem.Spacing.xl)

                Spacer(minLength: 0)

                // Bottom action
                bottomAction
                    .padding(.bottom, DesignSystem.Spacing.xl)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
        }
        .interactiveDismissDisabled()
        .onChange(of: state.stage) { _, newStage in
            if newStage == .completed {
                Haptics.processingComplete()
            } else if newStage == .failed {
                Haptics.error()
            }
        }
    }

    // MARK: - Copy

    private var headline: String {
        switch state.stage {
        case .failed: return "Something interrupted"
        case .completed: return "Found something"
        default: return "\(state.stage.displayName)…"
        }
    }

    private var subline: String {
        switch state.stage {
        case .watching: return "Reading every frame of the reel"
        case .listening: return "Listening for audio, voice, music"
        case .identifying: return "Detecting places, objects, text"
        case .lookingUp: return "Matching against maps & knowledge"
        case .enriching: return "Fetching details, photos, hours"
        case .organizing: return "Grouping into your collections"
        case .completed: return "Here's what that reel was hiding"
        case .failed: return "Give it another go when you're ready"
        }
    }

    // MARK: - Atmospheres

    private var scanAtmosphere: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<4) { i in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    DesignSystem.Colors.lime.opacity(0),
                                    DesignSystem.Colors.lime.opacity(0.18),
                                    DesignSystem.Colors.lime.opacity(0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: size * 0.9, height: 3)
                        .offset(y: (size * 0.5 - 1.5) * (2 * scanPhase - 1))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
        }
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
                    scanPhase = 1
                }
            }
        }
    }

    private var listeningAtmosphere: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            TimelineView(.animation(minimumInterval: 1/30)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                HStack(alignment: .center, spacing: 6) {
                    ForEach(0..<28) { index in
                        let wave = sin(t * 3.5 + Double(index) * 0.45)
                        let amplitude = 0.12 + abs(wave) * 0.35
                        let barHeight = height * amplitude
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        DesignSystem.Colors.coral.opacity(0.4),
                                        DesignSystem.Colors.coral.opacity(0.8)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 3, height: barHeight)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .allowsHitTesting(false)
        }
    }

    private var orbitAtmosphere: some View {
        ZStack {
            // Orbit paths
            ForEach(0..<3) { ring in
                Circle()
                    .strokeBorder(
                        DesignSystem.Colors.subtleBorder,
                        style: StrokeStyle(lineWidth: 1, dash: [8, 12])
                    )
                    .frame(width: 280 + CGFloat(ring) * 70, height: 280 + CGFloat(ring) * 70)
            }

            // Orbiting particles
            ForEach(0..<6) { i in
                let angle = Double(i) / 6 * 360
                let radius = 140 + CGFloat(i % 3) * 35
                Circle()
                    .fill(
                        i.isEven
                        ? DesignSystem.Colors.lime
                        : DesignSystem.Colors.coral
                    )
                    .frame(width: i.isEven ? 8 : 6, height: i.isEven ? 8 : 6)
                    .shadow(
                        color: (i.isEven ? DesignSystem.Colors.lime : DesignSystem.Colors.coral).opacity(0.5),
                        radius: 8
                    )
                    .offset(y: -radius)
                    .rotationEffect(.degrees(angle + orbitRotation))
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            if !reduceMotion {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                    orbitRotation = 360
                }
            }
        }
    }

    @State private var scanPhase: CGFloat = 0
    @State private var orbitRotation: Double = 0

    // MARK: - Reel Preview

    private var reelPreview: some View {
        ZStack {
            if let url = state.reelPreview?.thumbnailUrl {
                RemoteImage(url: url)
                    .frame(width: 172, height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
                    .scaleEffect(pulseScale)
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 172, height: 300)
                    .overlay {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40, weight: .light))
                            .foregroundStyle(DesignSystem.Colors.lime)
                    }
                    .scaleEffect(pulseScale)
            }
        }
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.3 : 0.12),
            radius: 28,
            y: 16
        )
        .animation(
            reduceMotion ? .linear(duration: 0.01) :
            .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
            value: pulseScale
        )
    }

    private var pulseScale: CGFloat {
        guard !reduceMotion else { return 1 }
        switch state.stage {
        case .watching: return 1.025
        case .listening: return 1.012
        case .identifying: return 1.018
        default: return 1.0
        }
    }

    // MARK: - Completed Overlay

    private var completedOverlay: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous)
                .fill(.ultraThinMaterial)
                .frame(width: 172, height: 300)

            VStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: "checkmark")
                    .font(.system(size: 44, weight: .bold))
                    .foregroundStyle(DesignSystem.Colors.lime)
                    .symbolEffect(.bounce, options: .repeat(1))

                Text("Discovered")
                    .fontStyle(DesignSystem.Typography.caption, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.secondaryText)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl, style: .continuous))
    }

    // MARK: - Bottom Action

    @ViewBuilder
    private var bottomAction: some View {
        switch state.stage {
        case .completed:
            Button {
                Haptics.tap()
                onComplete()
            } label: {
                Text("See the discovery")
                    .fontStyle(DesignSystem.Typography.button, colorScheme: colorScheme)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.md + 4)
                    .background(DesignSystem.Colors.lime, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            }
            .buttonStyle(TactileCardStyle(scale: 0.97))
            .transition(.scale(scale: 0.95).combined(with: .opacity))

        case .failed:
            VStack(spacing: DesignSystem.Spacing.md) {
                Text("Something went wrong")
                    .fontStyle(DesignSystem.Typography.sectionTitle, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.coral)

                Button(action: onRetry) {
                    Text("Try again")
                        .fontStyle(DesignSystem.Typography.button, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md + 4)
                        .background(DesignSystem.Colors.surface, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                                .stroke(DesignSystem.Colors.subtleBorder, lineWidth: 0.5)
                        )
                }
                .buttonStyle(TactileCardStyle(scale: 0.97))
            }
            .transition(.scale(scale: 0.95).combined(with: .opacity))

        default:
            Button(action: onComplete) {
                Text("Show me anyway")
                    .fontStyle(DesignSystem.Typography.buttonSmall, colorScheme: colorScheme)
                    .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DesignSystem.Spacing.sm)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Progress Pip

struct ProgressPip: View {
    let stage: ProcessingStage
    let current: ProcessingStage
    let progress: Double
    let reduceMotion: Bool

    @Environment(\.colorScheme) private var colorScheme

    private var allStages: [ProcessingStage] {
        ProcessingStage.allCases
    }

    private var stageIndex: Int { allStages.firstIndex(of: stage) ?? 0 }
    private var currentIndex: Int { allStages.firstIndex(of: current) ?? 0 }

    private var isActive: Bool { stageIndex <= currentIndex }
    private var isCurrent: Bool { stage == current }
    private var isCompleted: Bool { stageIndex < currentIndex || (isCurrent && progress >= 1.0) }

    var body: some View {
        HStack(spacing: 0) {
            // Pip
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.subtleBorder, lineWidth: 1.5)
                    .frame(width: 10, height: 10)

                if isCompleted {
                    Circle()
                        .fill(DesignSystem.Colors.lime)
                        .frame(width: 10, height: 10)
                        .transition(.scale.combined(with: .opacity))
                } else if isCurrent {
                    Circle()
                        .fill(DesignSystem.Colors.lime)
                        .frame(width: 10, height: 10)
                        .scaleEffect(pulseScale)
                        .animation(
                            reduceMotion ? .linear(duration: 0.01) :
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: pulseScale
                        )
                }
            }

            // Connector line (except last)
            if stageIndex < allStages.count - 1 {
                Rectangle()
                    .fill(
                        stageIndex < currentIndex
                        ? DesignSystem.Colors.lime
                        : DesignSystem.Colors.subtleBorder
                    )
                    .frame(height: 1.5)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(Motion.standard.animation, value: isActive)
        .animation(Motion.smooth.animation, value: isCompleted)
    }

    private var pulseScale: CGFloat {
        guard !reduceMotion, isCurrent, !isCompleted else { return 1 }
        return 1.3
    }
}

extension Int {
    var isEven: Bool { self % 2 == 0 }
}