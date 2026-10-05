import SwiftUI

struct ActionButtons: View {
    let actions: [Action]
    let onSave: () -> Void
    let onShare: () -> Void
    let onOpenURL: (String) -> Void
    var isSaved: Bool = false

    @State private var saveBurst = false

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if let openAction = actions.first(where: { $0.url != nil && $0.type != .save && $0.type != .share }) {
                primaryButton(openAction)
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                if actions.contains(where: { $0.type == .save }) {
                    saveButton
                }

                if actions.contains(where: { $0.type == .share }) {
                    secondaryButton(icon: "square.and.arrow.up", label: "Share", action: onShare)
                }
            }
        }
    }

    private var saveButton: some View {
        Button {
            Haptics.bookmark()
            saveBurst = false
            withAnimation(Motion.quick.animation) { saveBurst = true }
            onSave()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(Motion.smooth.animation) { saveBurst = false }
            }
        } label: {
            ZStack {
                Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        isSaved
                        ? DesignSystem.Colors.lime
                        : DesignSystem.Colors.lime
                    )
                    .symbolEffect(.bounce, options: .repeat(1), value: isSaved)
                    .contentTransition(.symbolEffect(.replace))

                if saveBurst {
                    SaveBurst(trigger: 1)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: 48, height: 48)
            .background(
                isSaved
                ? DesignSystem.Colors.lime.opacity(0.16)
                : DesignSystem.Colors.lime.opacity(0.12),
                in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                    .strokeBorder(
                        isSaved ? DesignSystem.Colors.lime : .clear,
                        lineWidth: 1.5
                    )
            }
            .scaleEffect(saveBurst ? 1.22 : 1)
            .rotationEffect(.degrees(saveBurst ? -6 : 0))
        }
        .buttonStyle(TactileCardStyle(scale: 0.9))
        .accessibilityLabel(isSaved ? "Saved" : "Save")
        .contentTransition(.symbolEffect(.replace))
    }

    private func primaryButton(_ action: Action) -> some View {
        Button {
            Haptics.tap()
            if let url = action.url {
                onOpenURL(url)
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: action.icon ?? action.type.systemIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .contentTransition(.symbolEffect(.replace))
                Text(action.label)
                    .fontStyle(DesignSystem.Typography.button, colorScheme: colorScheme)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.lime, in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
            .shadow(
                color: DesignSystem.Colors.lime.opacity(0.3),
                radius: 12,
                y: 4
            )
        }
        .buttonStyle(TactileCardStyle(scale: 0.96))
    }

    private func secondaryButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(DesignSystem.Colors.lime)
                .frame(width: 48, height: 48)
                .background(
                    DesignSystem.Colors.lime.opacity(0.12),
                    in: RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous)
                )
        }
        .buttonStyle(TactileCardStyle(scale: 0.9))
        .accessibilityLabel(label)
    }
}