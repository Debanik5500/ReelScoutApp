import SwiftUI

struct DropZone: View {
    let onDrop: (Reel) -> Void
    var isActive: Bool = false

    @State private var dragPosition: CGSize = .zero
    @State private var isDragging = false
    @State private var magneticIntensity: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // Ambient pulse ring
            Circle()
                .stroke(
                    DesignSystem.Colors.lime.opacity(0.3 * pulseScale),
                    lineWidth: 2
                )
                .frame(width: 140 * pulseScale, height: 140 * pulseScale)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: pulseScale
                )

            // Inner glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.Colors.lime.opacity(magneticIntensity * 0.15),
                            DesignSystem.Colors.lime.opacity(magneticIntensity * 0.05),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .animation(Motion.smooth.animation, value: magneticIntensity)

            // Drop target
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 72, height: 72)
                    .shadow(
                        color: .black.opacity(colorScheme == .dark ? 0.25 : 0.1),
                        radius: 12,
                        y: 6
                    )
                    .overlay(
                        Circle()
                            .strokeBorder(
                                DesignSystem.Colors.lime.opacity(0.3 + magneticIntensity * 0.5),
                                lineWidth: isActive ? 3 : 1.5
                            )
                    )

                Image(systemName: "arrow.down")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(DesignSystem.Colors.lime)
                    .scaleEffect(isActive ? 1.1 : 1.0)
                    .rotationEffect(.degrees(isActive ? -5 : 0))
                    .animation(Motion.quick.animation, value: isActive)
            }
            .scaleEffect(1.0 + magneticIntensity * 0.12)
            .offset(dragPosition)
        }
        .frame(width: 160, height: 160)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseScale = 1.15
            }
        }
        .onChange(of: isActive) { _, new in
            withAnimation(Motion.standard.animation) {
                magneticIntensity = new ? 1.0 : 0.0
            }
        }
    }
}

// MARK: - Drag Preview (for Share Extension)

struct DropZoneDragPreview: View {
    let source: ReelSource
    let onDragChanged: (CGPoint) -> Void
    let onDragEnded: (Bool) -> Void

    @State private var isDragging = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        // Source indicator
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: source.type.iconName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(sourceColor)
            Text(source.type.displayName)
                .fontStyle(DesignSystem.Typography.callout, colorScheme: colorScheme)
                .foregroundStyle(DesignSystem.Colors.primaryText)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.surface, in: Capsule())
        .shadow(
            color: .black.opacity(0.15),
            radius: 12,
            y: 6
        )
        .overlay(
            Capsule()
                .strokeBorder(sourceColor.opacity(0.5), lineWidth: 2)
        )
        .scaleEffect(isDragging ? 1.05 : 1.0)
        .animation(Motion.quick.animation, value: isDragging)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        Haptics.tap()
                    }
                    onDragChanged(value.location)
                }
                .onEnded { value in
                    isDragging = false
                    let dropped = value.translation.width > -50 && value.translation.width < 50
                    onDragEnded(dropped)
                    if dropped {
                        Haptics.dropZoneSuccess()
                    }
                }
        )
    }

    private var sourceColor: SwiftUI.Color {
        switch source.type {
        case .instagram: return DesignSystem.Colors.instagram
        case .tiktok: return DesignSystem.Colors.tiktok
        case .youtube: return DesignSystem.Colors.youtube
        case .other, .unknown: return DesignSystem.Colors.tertiaryText
        default: return DesignSystem.Colors.tertiaryText
        }
    }
}