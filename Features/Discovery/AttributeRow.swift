import SwiftUI

struct AttributeRow: View {
    let attribute: Attribute
    var onTap: (() -> Void)? = nil

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            Haptics.selection()
            onTap?()
        }) {
            HStack(spacing: DesignSystem.Spacing.md) {
                Image(systemName: attribute.type?.icon ?? "questionmark.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(attributeColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(attribute.label)
                        .fontStyle(DesignSystem.Typography.metadata, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                    Text(attribute.value)
                        .fontStyle(DesignSystem.Typography.body, colorScheme: colorScheme)
                        .foregroundStyle(DesignSystem.Colors.primaryText)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if onTap != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.tertiaryText)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg, style: .continuous))
        }
        .buttonStyle(TactileCardStyle(scale: 0.98))
        .disabled(onTap == nil)
        .opacity(onTap == nil ? 0.5 : 1)
    }

    private var attributeColor: SwiftUI.Color {
        switch attribute.type {
        case .location: return DesignSystem.Colors.coral
        case .time: return DesignSystem.Colors.lavender
        case .category: return DesignSystem.Colors.lime
        case .price: return DesignSystem.Colors.lime
        case .rating: return DesignSystem.Colors.coral
        case .url: return DesignSystem.Colors.lavender
        case .phone: return DesignSystem.Colors.lavender
        case .hours: return DesignSystem.Colors.lime
        case .website: return DesignSystem.Colors.lavender
        case .address: return DesignSystem.Colors.coral
        case .distance: return DesignSystem.Colors.lavender
        case .unknown: return DesignSystem.Colors.tertiaryText
        case .none: return DesignSystem.Colors.tertiaryText
        case .some(let type):
            switch type {
            case .location: return DesignSystem.Colors.coral
            case .time: return DesignSystem.Colors.lavender
            case .category: return DesignSystem.Colors.lime
            case .price: return DesignSystem.Colors.lime
            case .rating: return DesignSystem.Colors.coral
            case .url: return DesignSystem.Colors.lavender
            case .phone: return DesignSystem.Colors.lavender
            case .hours: return DesignSystem.Colors.lime
            case .website: return DesignSystem.Colors.lavender
            case .address: return DesignSystem.Colors.coral
            case .distance: return DesignSystem.Colors.lavender
            case .unknown: return DesignSystem.Colors.tertiaryText
            }
        }
    }
}