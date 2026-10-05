import SwiftUI

/// Press = compress the whole card, zoom the image, nudge the metadata, spring back.
/// Applies to any view; pair with `PressStateKey` when the image needs its own zoom.
struct PressableCardStyle: ButtonStyle {
    var scale: CGFloat = 0.965
    var brightness: Double = 0.02

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.isCardPressed, configuration.isPressed)
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -brightness : 0)
            .animation(
                configuration.isPressed ? Motion.micro.animation : Motion.quick.animation,
                value: configuration.isPressed
            )
    }
}

extension ButtonStyle where Self == PressableCardStyle {
    static var tactile: PressableCardStyle { PressableCardStyle() }
    static func tactile(scale: CGFloat) -> PressableCardStyle {
        PressableCardStyle(scale: scale)
    }
}

/// Press state shared between a button and the media inside it.
struct PressStateKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isCardPressed: Bool {
        get { self[PressStateKey.self] }
        set { self[PressStateKey.self] = newValue }
    }
}

extension View {
    /// Feed press state down to children (image zoom, metadata shift).
    func cardPressState(_ pressed: Bool) -> some View {
        environment(\.isCardPressed, pressed)
    }

    /// Standalone tactile press for non-button surfaces.
    func tactileSurface() -> some View {
        modifier(TactileSurface())
    }
}

private struct TactileSurface: ViewModifier {
    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Self.Content) -> some View {
        content
            .scaleEffect(pressed && !reduceMotion ? 0.97 : 1)
            .animation(pressed ? Motion.micro.animation : Motion.quick.animation, value: pressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressed else { return }
                        pressed = true
                        Haptics.cardPress()
                    }
                    .onEnded { _ in pressed = false }
            )
    }
}
