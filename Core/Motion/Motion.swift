import SwiftUI

enum Motion {
    static let micro = Spring(response: 0.18, dampingFraction: 0.88, blendDuration: 0.1)
    static let quick = Spring(response: 0.22, dampingFraction: 0.85, blendDuration: 0.1)
    static let standard = Spring(response: 0.35, dampingFraction: 0.8, blendDuration: 0.15)
    static let smooth = Spring(response: 0.45, dampingFraction: 0.75, blendDuration: 0.2)
    static let hero = Spring(response: 0.65, dampingFraction: 0.78, blendDuration: 0.25)
    static let cinematic = Spring(response: 0.85, dampingFraction: 0.82, blendDuration: 0.3)

    struct Spring {
        let response: Double
        let dampingFraction: Double
        let blendDuration: Double

        var animation: Animation {
            .interactiveSpring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }

        var animationLinear: Animation {
            .spring(response: response, dampingFraction: dampingFraction, blendDuration: blendDuration)
        }
    }
}

extension View {
    func withMicroSpring() -> some View {
        self.animation(Motion.micro.animation, value: UUID())
    }

    func withQuickSpring() -> some View {
        self.animation(Motion.quick.animation, value: UUID())
    }

    func withStandardSpring() -> some View {
        self.animation(Motion.standard.animation, value: UUID())
    }

    func withSmoothSpring() -> some View {
        self.animation(Motion.smooth.animation, value: UUID())
    }

    func withHeroSpring() -> some View {
        self.animation(Motion.hero.animation, value: UUID())
    }

    func withCinematicSpring() -> some View {
        self.animation(Motion.cinematic.animation, value: UUID())
    }
}

struct ReducedMotionKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isReducedMotion: Bool {
        get { self[ReducedMotionKey.self] }
        set { self[ReducedMotionKey.self] = newValue }
    }
}

extension View {
    func respectsReducedMotion(_ animation: Animation?) -> some View {
        EnvironmentReader { env in
            if env.isReducedMotion {
                self.animation(.easeInOut(duration: 0.15), value: UUID())
            } else {
                self.animation(animation, value: UUID())
            }
        }
    }
}

struct EnvironmentReader<Content: View>: View {
    @Environment(\.isReducedMotion) private var isReducedMotion
    let content: (EnvironmentValues) -> Content

    init(@ViewBuilder content: @escaping (EnvironmentValues) -> Content) {
        self.content = content
    }

    var body: some View {
        content(EnvironmentValues())
    }
}