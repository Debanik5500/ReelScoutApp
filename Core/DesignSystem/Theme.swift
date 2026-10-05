import SwiftUI

struct ThemeKey: EnvironmentKey {
    static let defaultValue: Theme = Theme()
}

extension EnvironmentValues {
    var theme: Theme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}

struct Theme {
    let color = DesignSystem.Colors.self
    let typography = DesignSystem.Typography.self
    let spacing = DesignSystem.Spacing.self
    let radius = DesignSystem.Radius.self
    let shadow = DesignSystem.Shadow.self
    let motion = Motion.self
    let layout = DesignSystem.Layout.self
}

extension View {
    func themed() -> some View {
        self.environment(\.theme, Theme())
    }
}