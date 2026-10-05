import SwiftUI

/// Design tokens for Kept. Colors switch automatically with the system
/// appearance via UIColor dynamic providers, so screens never branch on
/// colorScheme themselves.
enum Theme {
    static let background = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x141210) : UIColor(hex: 0xF6F1EA) })
    static let surface = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x1F1C19) : UIColor(hex: 0xFFFFFF) })
    static let surface2 = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x24201C) : UIColor(hex: 0xECE5DB) })
    static let text = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xF3EEE7) : UIColor(hex: 0x1C1B19) })
    static let textSecondary = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xA39B90) : UIColor(hex: 0x6E685F) })
    static let accent = Color(hex: 0xC9401F)
    static let accentHighlight = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xFF8A66) : UIColor(hex: 0xC9401F) })
    static let placeFg = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x7FD1C4) : UIColor(hex: 0x245E57) })
    static let placeBg = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x17312E) : UIColor(hex: 0xE4EFEC) })
    static let aiFg = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xCDB8F0) : UIColor(hex: 0x5B3F86) })
    static let aiBg = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x2A2238) : UIColor(hex: 0xEFE6F7) })
    static let success = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x2E8C80) : UIColor(hex: 0x245E57) })

    enum Radius {
        static let pin: CGFloat = 22
        static let card: CGFloat = 28
        static let sheet: CGFloat = 36
        static let chip: CGFloat = 99
    }

    enum Font {
        static func display(_ size: CGFloat, italic: Bool = false) -> SwiftUI.Font {
            let name = italic ? "InstrumentSerif-Italic" : "InstrumentSerif-Regular"
            return SwiftUI.Font.custom(name, size: size)
        }
        static func body(_ size: CGFloat, weight: SwiftUI.Font.Weight = .regular) -> SwiftUI.Font {
            .system(size: size, weight: weight, design: .default)
        }
    }

    enum Spring {
        static let standard = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let snappy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(uiColor: UIColor(hex: hex))
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

/// Scales a card down slightly while pressed, matching the design's button feel.
/// Implemented as a ButtonStyle (not a parallel DragGesture) so it never
/// competes with the Button's own tap recognition — a raw `.simultaneousGesture`
/// drag on a Button's label can swallow the tap on real devices, which is why
/// this replaced the old `pressableScale()` view modifier.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Theme.Spring.snappy, value: configuration.isPressed)
    }
}
