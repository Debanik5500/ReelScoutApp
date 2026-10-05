import SwiftUI

struct TabBarPersonality: View {
    @Binding var selection: Tab
    let onSaveLanded: () -> Void

    @State private var pillPosition: CGFloat = 0
    @State private var saveBurst = false
    @State private var previousSelection: Tab?

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.theme) private var theme

    private let tabs: [Tab] = [.home, .saved, .collections, .processing]
    private let pillWidth: CGFloat = 56
    private let pillHeight: CGFloat = 42

    var body: some View {
        GeometryReader { geo in
            let tabWidth = geo.size.width / CGFloat(tabs.count)
            let barHeight: CGFloat = 56

            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(DesignSystem.Colors.surfaceElevated.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(DesignSystem.Colors.subtleBorder.opacity(0.5), lineWidth: 0.5)
                    )
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.25 : 0.08),
                        radius: 20,
                        y: -4
                    )
                    .frame(height: barHeight + 12)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 4)
                    .ignoresSafeArea(edges: .bottom)

                // Moving pill indicator
                Capsule()
                    .fill(DesignSystem.Colors.lime)
                    .frame(width: pillWidth, height: pillHeight)
                    .shadow(
                        color: DesignSystem.Colors.lime.opacity(0.35),
                        radius: 14,
                        y: 6
                    )
                    .overlay(
                        Image(systemName: selectedTabIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white)
                    )
                    .offset(x: pillPosition, y: -barHeight/2 - 6)
                    .animation(Motion.hero.animation, value: pillPosition)
                    .animation(Motion.quick.animation, value: saveBurst)
                    .scaleEffect(saveBurst ? 1.3 : 1.0)
                    .allowsHitTesting(false)

                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        Button {
                            Haptics.selection()
                            previousSelection = selection
                            withAnimation(Motion.hero.animation) {
                                selection = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tabIcon(tab))
                                    .font(.system(size: 22, weight: selection == tab ? .semibold : .regular))
.foregroundStyle(
                            selection == tab
                            ? .white
                            : DesignSystem.Colors.secondaryText
                        )
                                    .symbolEffect(.bounce, options: .repeat(1), value: selection == tab)

                                Text(tabLabel(tab))
                                    .fontStyle(DesignSystem.Typography.stamp, colorScheme: colorScheme)
.foregroundStyle(
                            selection == tab
                            ? .white
                            : DesignSystem.Colors.tertiaryText
                        )
                                    .contentTransition(.opacity)
                            }
                            .frame(width: tabWidth, height: barHeight)
                        }
                        .buttonStyle(.plain)
                        .disabled(selection == tab)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
            }
            .frame(height: barHeight + 16)
        }
        .frame(height: 68)
        .onChange(of: selection) { _, new in
            updatePill(for: new, geoWidth: UIScreen.main.bounds.width)
        }
        .onChange(of: saveBurst) { _, new in
            if !new { onSaveLanded() }
        }
        .onAppear {
            updatePill(for: selection, geoWidth: UIScreen.main.bounds.width)
        }
    }

    private func updatePill(for tab: Tab, geoWidth: CGFloat) {
        let index = tabs.firstIndex(of: tab) ?? 0
        let tabWidth = geoWidth / CGFloat(tabs.count)
        let centerX = tabWidth * CGFloat(index) + tabWidth / 2
        let screenCenter = geoWidth / 2
        pillPosition = centerX - screenCenter
    }

    private var selectedTabIcon: String {
        tabIcon(selection)
    }

    private func tabIcon(_ tab: Tab) -> String {
        switch tab {
        case .home: return "house"
        case .saved: return "bookmark"
        case .collections: return "folder"
        case .processing: return "magnifyingglass"
        }
    }

    private func tabLabel(_ tab: Tab) -> String {
        switch tab {
        case .home: return "Home"
        case .saved: return "Saved"
        case .collections: return "Piles"
        case .processing: return "Scout"
        }
    }
}

struct SaveFlightOverlay: View {
    @EnvironmentObject var appState: AppState

    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let flight = appState.saveFlight {
            let from = flight.from
            let to = CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 80)

            TimelineView(.animation(minimumInterval: 1/60)) { timeline in
                let t = min(1, timeline.date.timeIntervalSince(flight.start) / 0.6)
                let eased = easeOutCubic(t)
                let x = from.x + (to.x - from.x) * eased
                let y = from.y + (to.y - from.y) * eased
                let scale = 1.0 - 0.3 * eased
                let rotation = -20 * eased
                let opacity = 1 - eased

                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.lime)
                        .frame(width: 10, height: 10)

                    Circle()
                        .strokeBorder(DesignSystem.Colors.lime.opacity(0.6), lineWidth: 2)
                        .frame(width: 20 + 30 * eased, height: 20 + 30 * eased)
                }
                .position(x: x, y: y)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .opacity(opacity)
                .allowsHitTesting(false)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    appState.clearSaveFlight()
                }
            }
        }
    }

    private func easeOutCubic(_ t: Double) -> Double {
        1 - pow(1 - t, 3)
    }
}