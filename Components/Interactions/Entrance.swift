import SwiftUI

// MARK: - Staggered entrance

/// Cards arrive one after another instead of all at once.
struct StaggeredEntrance<Content: View>: View {
    let content: Content
    let index: Int
    var delay: Double = 0.06
    var enabled: Bool = true

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 24)
            .blur(radius: hasAppeared ? 0 : 6)
            .scaleEffect(hasAppeared ? 1 : 0.94)
            .animation(
                reduceMotion ? .easeOut(duration: 0.12) :
                .spring(response: 0.65, dampingFraction: 0.8, blendDuration: 0.15)
                .delay(enabled ? Double(index) * delay : 0),
                value: hasAppeared
            )
            .onAppear {
                if enabled {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    func staggeredEntrance(index: Int, delay: Double = 0.06, enabled: Bool = true) -> some View {
        StaggeredEntrance(content: self, index: index, delay: delay, enabled: enabled)
    }
}

// MARK: - Entrance presets for common use cases

extension View {
    /// Primary content entrance - use for main cards
    func primaryEntrance(index: Int) -> some View {
        staggeredEntrance(index: index, delay: 0.07)
    }

    /// Secondary content entrance - use for supporting elements
    func secondaryEntrance(index: Int) -> some View {
        staggeredEntrance(index: index, delay: 0.05)
    }

    /// List item entrance
    func listItemEntrance(index: Int) -> some View {
        staggeredEntrance(index: index, delay: 0.04, enabled: index < 20)
    }
}

// MARK: - Hero reveal

struct HeroReveal<Content: View>: View {
    let content: Content

    @State private var phase = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .opacity(phase >= 1 ? 1 : 0)
            .offset(y: phase >= 1 ? 0 : 30)
            .blur(radius: phase >= 1 ? 0 : 8)
            .scaleEffect(phase >= 1 ? 1 : 0.9)
            .animation(
                reduceMotion ? .easeOut(duration: 0.2) :
                .spring(response: 0.75, dampingFraction: 0.82, blendDuration: 0.2),
                value: phase
            )
            .onAppear {
                withAnimation {
                    phase = 1
                }
            }
    }
}

extension View {
    func heroReveal() -> some View {
        HeroReveal(content: self)
    }
}

// MARK: - Content transition

struct ContentFade<Content: View>: View {
    let content: Content
    let isVisible: Bool

    var body: some View {
        content
            .opacity(isVisible ? 1 : 0)
            .animation(Motion.smooth.animation, value: isVisible)
    }
}

extension View {
    func contentFade(_ visible: Bool) -> some View {
        ContentFade(content: self, isVisible: visible)
    }
}