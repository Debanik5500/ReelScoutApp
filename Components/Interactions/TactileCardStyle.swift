import SwiftUI

struct TactileCardStyle: ButtonStyle {
    let scale: CGFloat
    let hapticOnPress: Bool

    init(scale: CGFloat = 0.96, hapticOnPress: Bool = true) {
        self.scale = scale
        self.hapticOnPress = hapticOnPress
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(Motion.micro.animation, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && hapticOnPress {
                    Haptics.cardPress()
                } else if !pressed {
                    Haptics.cardRelease()
                }
            }
    }
}