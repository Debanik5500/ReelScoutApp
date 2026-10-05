import SwiftUI

extension View {
    func fontStyle(_ style: DesignSystem.FontStyle, color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        let resolvedColor = color ?? DesignSystem.Colors.primaryText
        return self
            .font(style.font)
            .foregroundStyle(resolvedColor)
            .lineSpacing(style.lineHeight - style.size)
            .tracking(style.tracking)
    }

    func displayStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.display, color: color, colorScheme: colorScheme)
    }

    func heroStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.hero, color: color, colorScheme: colorScheme)
    }

    func editorialTitleStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.editorialTitle, color: color, colorScheme: colorScheme)
    }

    func sectionTitleStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.sectionTitle, color: color, colorScheme: colorScheme)
    }

    func bodyStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.body, color: color, colorScheme: colorScheme)
    }

    func bodyEmphasizedStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.bodyEmphasized, color: color, colorScheme: colorScheme)
    }

    func captionStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.caption, color: color, colorScheme: colorScheme)
    }

    func metadataStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.metadata, color: color, colorScheme: colorScheme)
    }

    func eyebrowStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.eyebrow, color: color, colorScheme: colorScheme)
    }

    func stampStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.stamp, color: color, colorScheme: colorScheme)
    }

    func buttonStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.button, color: color, colorScheme: colorScheme)
    }

    func buttonSmallStyle(color: SwiftUI.Color? = nil, colorScheme: ColorScheme = .light) -> some View {
        fontStyle(DesignSystem.Typography.buttonSmall, color: color, colorScheme: colorScheme)
    }
}

extension View {
    func paddingXS() -> some View { self.padding(DesignSystem.Spacing.xs) }
    func paddingSM() -> some View { self.padding(DesignSystem.Spacing.sm) }
    func paddingMD() -> some View { self.padding(DesignSystem.Spacing.md) }
    func paddingLG() -> some View { self.padding(DesignSystem.Spacing.lg) }
    func paddingXL() -> some View { self.padding(DesignSystem.Spacing.xl) }
    func paddingXXL() -> some View { self.padding(DesignSystem.Spacing.xxl) }
    func paddingXXXL() -> some View { self.padding(DesignSystem.Spacing.xxxl) }

    func paddingHorizontal(_ spacing: CGFloat) -> some View {
        self.padding(.horizontal, spacing)
    }

    func paddingVertical(_ spacing: CGFloat) -> some View {
        self.padding(.vertical, spacing)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    func cornerRadius(_ radius: DesignSystem.Radius.Type) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md, style: .continuous))
    }
}

extension View {
    func shadowWhisper() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.whisper.color,
            radius: DesignSystem.Shadow.whisper.radius,
            x: DesignSystem.Shadow.whisper.x,
            y: DesignSystem.Shadow.whisper.y
        )
    }

    func shadowSubtle() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.subtle.color,
            radius: DesignSystem.Shadow.subtle.radius,
            x: DesignSystem.Shadow.subtle.x,
            y: DesignSystem.Shadow.subtle.y
        )
    }

    func shadowCard() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.card.color,
            radius: DesignSystem.Shadow.card.radius,
            x: DesignSystem.Shadow.card.x,
            y: DesignSystem.Shadow.card.y
        )
    }

    func shadowElevated() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.elevated.color,
            radius: DesignSystem.Shadow.elevated.radius,
            x: DesignSystem.Shadow.elevated.x,
            y: DesignSystem.Shadow.elevated.y
        )
    }

    func shadowFloating() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.floating.color,
            radius: DesignSystem.Shadow.floating.radius,
            x: DesignSystem.Shadow.floating.x,
            y: DesignSystem.Shadow.floating.y
        )
    }
}

extension View {
    func surfaceBackground() -> some View {
        self.background(DesignSystem.Colors.surface)
    }

    func surfaceElevatedBackground() -> some View {
        self.background(DesignSystem.Colors.surfaceElevated)
    }

    func backgroundColor(_ color: DesignSystem.ThemeColor) -> some View {
        self.background(color.resolved(in: .light))
    }
}