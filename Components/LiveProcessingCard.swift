import SwiftUI

/// The grid card for a reel still being processed: blurred cover that
/// sharpens by step, a scan line, a progress ring, and four step bars.
/// Reusable so the Library grid and a possible "in progress" list share one look.
struct LiveProcessingCard: View {
    let reel: Reel
    let height: CGFloat

    fileprivate var failed: Bool { reel.status == .failed }
    fileprivate var queued: Bool { reel.status == .queued }
    fileprivate var step: Int { max(reel.status.stepIndex, 0) }
    fileprivate var sourceLabel: String {
        reel.author.isEmpty ? PlatformRegistry.platform(for: reel.platformID).displayName : reel.author
    }
    private var fraction: Double { (Double(step) + reel.progress) / 4 }
    private var blurRadius: CGFloat { max(2, 14 - CGFloat(step) * 4) }
    private var veilOpacity: Double { max(0, 0.5 - Double(step) * 0.09) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                ReelCover(reel: reel)
                    .aspectRatio(contentMode: .fill)
                    .frame(height: height)
                    .clipped()
                    .blur(radius: blurRadius)
                    .scaleEffect(1.15) // hide blur edge bleed
                    .animation(.easeInOut(duration: 1.0), value: blurRadius)

                if !failed && !queued { ScanLine(height: height) }

                Rectangle().fill(Theme.background.opacity(veilOpacity))

                VStack {
                    HStack {
                        HStack(spacing: 6) {
                            if failed {
                                Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10))
                            } else {
                                ProgressView().controlSize(.mini)
                            }
                            Text(reel.status.label).font(Theme.Font.body(11, weight: .bold))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Theme.surface, in: Capsule())
                        Spacer()
                    }
                    Spacer()
                    if queued {
                        Image(systemName: "hourglass").font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(Theme.text.opacity(0.7))
                            .frame(width: 56, height: 56)
                    } else if !failed {
                    ZStack {
                        Circle().stroke(Theme.text.opacity(0.1), lineWidth: 5)
                        Circle()
                            .trim(from: 0, to: fraction)
                            .stroke(Theme.accentHighlight, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("\(Int(fraction * 100))%").font(Theme.Font.display(18))
                    }
                    .frame(width: 56, height: 56)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(0..<4, id: \.self) { i in
                            Capsule().fill(i < step ? Theme.accentHighlight : Theme.text.opacity(0.14))
                                .frame(height: 4)
                        }
                    }
                }
                .padding(10)
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.pin, style: .continuous))

            if reel.isNamed {
                Text(reel.title ?? "").font(Theme.Font.body(14, weight: .semibold)).lineLimit(2)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ShimmerBar(width: 0.9)
                    ShimmerBar(width: 0.6)
                }
            }
            footer
        }
        .animation(Theme.Spring.standard, value: step)
    }
}

extension LiveProcessingCard {
    /// Failed cards count down to their automatic removal; tapping opens the retry screen.
    @ViewBuilder fileprivate var footer: some View {
        if failed {
            if let failedAt = reel.failedAt {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    let left = max(0, Int(ReelStore.failedGrace) - Int(context.date.timeIntervalSince(failedAt)))
                    Text("Tap to retry · removed in \(left / 60):\(String(format: "%02d", left % 60))")
                        .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary).lineLimit(2)
                }
            } else {
                Text("Tap to retry").font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
            }
        } else if queued {
            Text("Waiting in line · starts when the reel ahead is done")
                .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary).lineLimit(2)
        } else {
            Text("Step \(step + 1) of 4 · \(sourceLabel)")
                .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary).lineLimit(2)
        }
    }
}

private struct ScanLine: View {
    let height: CGFloat
    @State private var animate = false
    var body: some View {
        LinearGradient(colors: [.clear, .white.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 70)
            .offset(y: animate ? height + 40 : -80)
            .animation(.easeInOut(duration: 2.2).repeatForever(autoreverses: false), value: animate)
            .onAppear { animate = true }
    }
}

private struct ShimmerBar: View {
    let width: CGFloat
    @State private var animate = false
    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(Theme.surface2)
                .overlay(
                    LinearGradient(colors: [.clear, .white.opacity(0.25), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: geo.size.width * 0.4)
                        .offset(x: animate ? geo.size.width : -geo.size.width * 0.4)
                )
                .clipShape(Capsule())
        }
        .frame(width: nil, height: 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(x: width, y: 1, anchor: .leading)
        .animation(.linear(duration: 1.3).repeatForever(autoreverses: false), value: animate)
        .onAppear { animate = true }
    }
}
