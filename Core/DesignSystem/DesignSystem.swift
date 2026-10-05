import SwiftUI

// Backwards compatibility for existing code
typealias DSColor = DesignSystem.ThemeColor

struct DesignSystem {
    // Legacy alias
    typealias Color = ThemeColor

    struct Colors {
        static let background = Palette.background.resolved(in: .light)
        static let surface = Palette.surface.resolved(in: .light)
        static let surfaceElevated = Palette.surfaceElevated.resolved(in: .light)
        static let primaryText = Palette.primaryText.resolved(in: .light)
        static let secondaryText = Palette.secondaryText.resolved(in: .light)
        static let tertiaryText = Palette.tertiaryText.resolved(in: .light)
        static let lime = Palette.lime.resolved(in: .light)
        static let coral = Palette.coral.resolved(in: .light)
        static let lavender = Palette.lavender.resolved(in: .light)
        static let subtleBorder = Palette.subtleBorder.resolved(in: .light)
        static let divider = Palette.divider.resolved(in: .light)
        static let mutedMetadata = Palette.mutedMetadata.resolved(in: .light)
        static let instagram = Palette.instagram.resolved(in: .light)
        static let tiktok = Palette.tiktok.resolved(in: .light)
        static let youtube = Palette.youtube.resolved(in: .light)
        static let overlay = Palette.overlay.resolved(in: .light)

        // Legacy aliases for backward compatibility
        static let primaryLabel = Palette.primaryText.resolved(in: .light)
        static let secondaryLabel = Palette.secondaryText.resolved(in: .light)
        static let tertiaryLabel = Palette.tertiaryText.resolved(in: .light)
        static let cardBackground = Palette.surface.resolved(in: .light)
        static let groupedBackground = Palette.background.resolved(in: .light)
    }

    struct Palette {
        static var background: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "FDF8F0"), dark: SwiftUI.Color(hex: "1A1816")) }
        static var surface: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "FAF5EB"), dark: SwiftUI.Color(hex: "23201E")) }
        static var surfaceElevated: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "FFFFFF"), dark: SwiftUI.Color(hex: "2A2725")) }
        static var primaryText: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "1C1A18"), dark: SwiftUI.Color(hex: "F5F2EE")) }
        static var secondaryText: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "4A4642"), dark: SwiftUI.Color(hex: "C8C3BC")) }
        static var tertiaryText: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "78736D"), dark: SwiftUI.Color(hex: "9A948C")) }
        static let lime = ThemeColor(light: SwiftUI.Color(hex: "A8D600"), dark: SwiftUI.Color(hex: "B8E800"))
        static let coral = ThemeColor(light: SwiftUI.Color(hex: "E86C5C"), dark: SwiftUI.Color(hex: "F08070"))
        static let lavender = ThemeColor(light: SwiftUI.Color(hex: "B8A8E8"), dark: SwiftUI.Color(hex: "C8B8F0"))
        static var subtleBorder: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "E8E2D8"), dark: SwiftUI.Color(hex: "3A3530")) }
        static var divider: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "EDE7DD"), dark: SwiftUI.Color(hex: "33302C")) }
        static var mutedMetadata: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "9E988F"), dark: SwiftUI.Color(hex: "8A847B")) }
        static let instagram = ThemeColor(hex: "E4405F")
        static let tiktok = ThemeColor(hex: "000000")
        static let youtube = ThemeColor(hex: "FF0000")
        static var overlay: ThemeColor { ThemeColor(light: SwiftUI.Color(hex: "1C1A18").opacity(0.6), dark: SwiftUI.Color(hex: "000000").opacity(0.7)) }
    }

    struct ThemeColor: Equatable {
        let light: SwiftUI.Color
        let dark: SwiftUI.Color

        init(light: SwiftUI.Color, dark: SwiftUI.Color) {
            self.light = light
            self.dark = dark
        }

        init(hex: String) {
            self.light = SwiftUI.Color(hex: hex)
            self.dark = SwiftUI.Color(hex: hex)
        }

        func resolved(in colorScheme: ColorScheme) -> SwiftUI.Color {
            colorScheme == .dark ? dark : light
        }

        // Legacy static properties for backward compatibility
        static let background = Palette.background
        static let surface = Palette.surface
        static let surfaceElevated = Palette.surfaceElevated
        static let primaryText = Palette.primaryText
        static let secondaryText = Palette.secondaryText
        static let tertiaryText = Palette.tertiaryText
        static let lime = Palette.lime
        static let coral = Palette.coral
        static let lavender = Palette.lavender
        static let subtleBorder = Palette.subtleBorder
        static let divider = Palette.divider
        static let mutedMetadata = Palette.mutedMetadata
        static let instagram = Palette.instagram
        static let tiktok = Palette.tiktok
        static let youtube = Palette.youtube
        static let overlay = Palette.overlay

        // Legacy aliases
        static let primaryLabel = Palette.primaryText.resolved(in: .light)
        static let secondaryLabel = Palette.secondaryText.resolved(in: .light)
        static let tertiaryLabel = Palette.tertiaryText.resolved(in: .light)
        static let cardBackground = Palette.surface.resolved(in: .light)
        static let groupedBackground = Palette.background.resolved(in: .light)
    }

    struct Typography {
        static let display = FontStyle(size: 56, weight: .medium, design: .serif, leading: 1.1)
        static let hero = FontStyle(size: 40, weight: .medium, design: .serif, leading: 1.15)
        static let editorialTitle = FontStyle(size: 28, weight: .semibold, design: .serif, leading: 1.2)
        static let sectionTitle = FontStyle(size: 20, weight: .semibold, design: .default, leading: 1.25)
        static let body = FontStyle(size: 16, weight: .regular, design: .default, leading: 1.5)
        static let bodyEmphasized = FontStyle(size: 16, weight: .medium, design: .default, leading: 1.5)
        static let caption = FontStyle(size: 13, weight: .regular, design: .default, leading: 1.4)
        static let metadata = FontStyle(size: 11, weight: .regular, design: .default, leading: 1.3)
        static let eyebrow = FontStyle(size: 11, weight: .semibold, design: .default, leading: 1.2, tracking: 0.08)
        static let stamp = FontStyle(size: 10, weight: .medium, design: .default, leading: 1.2, tracking: 0.12)
        static let button = FontStyle(size: 15, weight: .semibold, design: .default, leading: 1.0, tracking: 0.02)
        static let buttonSmall = FontStyle(size: 13, weight: .semibold, design: .default, leading: 1.0, tracking: 0.04)

        // Legacy aliases
        static let largeTitle = FontStyle(size: 34, weight: .bold, design: .default, leading: 1.2)
        static let title1 = FontStyle(size: 28, weight: .bold, design: .default, leading: 1.25)
        static let title2 = FontStyle(size: 22, weight: .bold, design: .default, leading: 1.3)
        static let title3 = FontStyle(size: 20, weight: .semibold, design: .default, leading: 1.3)
        static let headline = FontStyle(size: 17, weight: .semibold, design: .default, leading: 1.3)
        static let subheadline = FontStyle(size: 15, weight: .regular, design: .default, leading: 1.4)
        static let callout = FontStyle(size: 16, weight: .regular, design: .default, leading: 1.4)
        static let footnote = FontStyle(size: 13, weight: .regular, design: .default, leading: 1.4)
        static let caption1 = FontStyle(size: 12, weight: .regular, design: .default, leading: 1.4)
        static let caption2 = FontStyle(size: 11, weight: .regular, design: .default, leading: 1.3)
    }

    struct FontStyle {
        let size: CGFloat
        let weight: Font.Weight
        let design: Font.Design
        let leading: CGFloat
        let tracking: CGFloat

        init(size: CGFloat, weight: Font.Weight, design: Font.Design, leading: CGFloat, tracking: CGFloat = 0) {
            self.size = size
            self.weight = weight
            self.design = design
            self.leading = leading
            self.tracking = tracking
        }

        var font: Font {
            .system(size: size, weight: weight, design: design)
        }

        var lineHeight: CGFloat {
            size * leading
        }

        func tracking(_ value: CGFloat) -> FontStyle {
            FontStyle(size: size, weight: weight, design: design, leading: leading, tracking: value)
        }

func resolve(for textStyle: Font.TextStyle, relativeTo: Font.TextStyle = .body) -> Font {
        let metrics = UIFontMetrics(forTextStyle: relativeTo.uiFontTextStyle)
        let baseFont = UIFont.preferredFont(forTextStyle: textStyle.uiFontTextStyle)
        let scaledFont = metrics.scaledFont(for: baseFont)
        var descriptor = scaledFont.fontDescriptor
        switch design {
        case .serif:
            if let serifDescriptor = descriptor.withDesign(.serif) {
                descriptor = serifDescriptor
            }
        case .rounded:
            if let roundedDescriptor = descriptor.withDesign(.rounded) {
                descriptor = roundedDescriptor
            }
        case .monospaced:
            if let monoDescriptor = descriptor.withDesign(.monospaced) {
                descriptor = monoDescriptor
            }
        default: break
        }
        var traits: [UIFontDescriptor.TraitKey: Any] = [:]
        switch weight {
        case .ultraLight: traits[.weight] = UIFont.Weight.ultraLight
        case .thin: traits[.weight] = UIFont.Weight.thin
        case .light: traits[.weight] = UIFont.Weight.light
        case .regular: traits[.weight] = UIFont.Weight.regular
        case .medium: traits[.weight] = UIFont.Weight.medium
        case .semibold: traits[.weight] = UIFont.Weight.semibold
        case .bold: traits[.weight] = UIFont.Weight.bold
        case .heavy: traits[.weight] = UIFont.Weight.heavy
        case .black: traits[.weight] = UIFont.Weight.black
        default: traits[.weight] = UIFont.Weight.regular
        }
        descriptor = descriptor.addingAttributes([.traits: traits])
        let designedFont = UIFont(descriptor: descriptor, size: scaledFont.pointSize)
        return Font(designedFont)
    }
    }

    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    struct Radius {
        static let none: CGFloat = 0
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let editorial: CGFloat = 4
        static let image: CGFloat = 8
        static let pill: CGFloat = 9999
    }

    struct Shadow {
        static let none = ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
        static let whisper = ShadowStyle(color: Palette.primaryText.resolved(in: .light).opacity(0.06), radius: 3, x: 0, y: 1)
        static let subtle = ShadowStyle(color: Palette.primaryText.resolved(in: .light).opacity(0.08), radius: 10, x: 0, y: 3)
        static let card = ShadowStyle(color: Palette.primaryText.resolved(in: .light).opacity(0.12), radius: 20, x: 0, y: 6)
        static let elevated = ShadowStyle(color: Palette.primaryText.resolved(in: .light).opacity(0.15), radius: 32, x: 0, y: 10)
        static let floating = ShadowStyle(color: Palette.primaryText.resolved(in: .light).opacity(0.18), radius: 48, x: 0, y: 20)

        struct ShadowStyle {
            let color: SwiftUI.Color
            let radius: CGFloat
            let x: CGFloat
            let y: CGFloat
        }
    }

    struct Motion {
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

    struct Layout {
        static let homeHorizontalPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 32
        static let itemSpacing: CGFloat = 16
        static let gridSpacing: CGFloat = 12
        static let cardCornerRadius: CGFloat = Radius.image
        static let buttonCornerRadius: CGFloat = Radius.pill
        static let sheetCornerRadius: CGFloat = Radius.xxl
        static let frameStackCornerRadius: CGFloat = Radius.sm
    }
}

extension DesignSystem.ThemeColor: View {
    var body: some View {
        GeometryReader { proxy in
            let scheme: ColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            self.resolved(in: scheme).ignoresSafeArea()
        }
    }
}

extension View {
    func designColor(_ color: DesignSystem.ThemeColor) -> some View {
        self.foregroundStyle(color.resolved(in: .light))
    }

    func background(_ color: DesignSystem.ThemeColor) -> some View {
        self.background(color.resolved(in: .light))
    }

    func designBackground(_ color: DesignSystem.ThemeColor) -> some View {
        GeometryReader { proxy in
            let scheme: ColorScheme = UITraitCollection.current.userInterfaceStyle == .dark ? .dark : .light
            self.background(color.resolved(in: scheme))
        }
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 1, 1, 1)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Font.TextStyle {
    var uiFontTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .body: return .body
        case .callout: return .callout
        case .subheadline: return .subheadline
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}

extension UIFont {
    func withWeight(_ weight: Font.Weight) -> Font {
        var traits: [UIFontDescriptor.TraitKey: Any] = [:]
        switch weight {
        case .ultraLight: traits[.weight] = UIFont.Weight.ultraLight
        case .thin: traits[.weight] = UIFont.Weight.thin
        case .light: traits[.weight] = UIFont.Weight.light
        case .regular: traits[.weight] = UIFont.Weight.regular
        case .medium: traits[.weight] = UIFont.Weight.medium
        case .semibold: traits[.weight] = UIFont.Weight.semibold
        case .bold: traits[.weight] = UIFont.Weight.bold
        case .heavy: traits[.weight] = UIFont.Weight.heavy
        case .black: traits[.weight] = UIFont.Weight.black
        default: traits[.weight] = UIFont.Weight.regular
        }
        let descriptor = fontDescriptor.addingAttributes([.traits: traits])
        return Font(UIFont(descriptor: descriptor, size: pointSize))
    }

    func withDesign(_ design: Font.Design) -> Font {
        var descriptor = fontDescriptor
        switch design {
        case .serif:
            if let serifDescriptor = descriptor.withDesign(.serif) {
                descriptor = serifDescriptor
            }
        case .rounded:
            if let roundedDescriptor = descriptor.withDesign(.rounded) {
                descriptor = roundedDescriptor
            }
        case .monospaced:
            if let monoDescriptor = descriptor.withDesign(.monospaced) {
                descriptor = monoDescriptor
            }
        default: break
        }
        return Font(UIFont(descriptor: descriptor, size: pointSize))
    }
}