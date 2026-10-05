import SwiftUI

/// Media-first image loading: shimmer while fetching, soft fade + scale on arrival.
/// Pass `zoom` to push the image out slightly while the card is pressed.
struct RemoteImage: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var zoom: CGFloat = 1

    @State private var loaded = false
    @State private var failed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isCardPressed) private var pressed

    private var effectiveZoom: CGFloat {
        pressed ? zoom + 0.06 : zoom
    }

    var body: some View {
        ZStack {
            if failed || url == nil {
                placeholder
            } else {
                AsyncImage(url: url.flatMap(URL.init(string:))) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: contentMode)
                            .transition(.opacity.combined(with: .scale(scale: 1.04)))
                            .onAppear {
                                withAnimation(reduceMotion ? .linear(duration: 0.1) : Motion.smooth.animation) {
                                    loaded = true
                                }
                            }
                    case .failure:
                        placeholder.onAppear { failed = true }
                    default:
                        shimmer
                    }
                }
            }
        }
        .scaleEffect(effectiveZoom)
        .animation(Motion.quick.animation, value: effectiveZoom)
        .clipped()
    }

    private var placeholder: some View {
        ZStack {
            DesignSystem.Colors.cardBackground
            Image(systemName: "photo")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(DesignSystem.Colors.tertiaryLabel)
        }
    }

    private var shimmer: some View {
        ZStack {
            DesignSystem.Colors.cardBackground
            ShimmerSweep()
        }
    }
}

/// A slow light sweep across a loading surface.
struct ShimmerSweep: View {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            LinearGradient(
                colors: [.clear, Color.white.opacity(0.65), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: width * 0.55)
            .offset(x: phase * width * 1.6)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
        }
        .clipped()
    }
}

#Preview {
    RemoteImage(url: "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800")
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 20))
}
