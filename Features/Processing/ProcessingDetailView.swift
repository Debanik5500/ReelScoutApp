import SwiftUI

/// Full-screen live status for one reel: steps ticking off, findings
/// appearing as chips, cover sharpening as it goes.
struct ProcessingDetailView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    let reelID: UUID

    private var reel: Reel? { store.reels.first { $0.id == reelID } }

    private let stepLabels = [
        ("Downloading the reel", "0:42 video"),
        ("Watching and listening", "captions + audio"),
        ("Picking key moments", "5 frames"),
        ("Finding places and a board", "1 place"),
    ]

    var body: some View {
        guard let reel else { return AnyView(EmptyView()) }
        let step = max(reel.status.stepIndex, 0)
        let done = reel.status == .ready

        return AnyView(
            ScrollView {
                VStack(spacing: 28) {
                    HStack {
                        Button { dismiss() } label: {
                            Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                                .frame(width: 44, height: 44).background(Theme.surface, in: Circle())
                        }
                        Spacer()
                        Text(done ? "Done" : "About \((4 - step) * 2)s left")
                            .font(Theme.Font.body(13, weight: .semibold))
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(Theme.surface, in: Capsule())
                    }
                    .padding(.horizontal, 20).padding(.top, 8)
                    .foregroundStyle(Theme.text)

                    ZStack {
                        Image.cover(reel.coverImageName).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 220, height: 300)
                            .blur(radius: done ? 0 : max(2, 16 - CGFloat(step) * 4))
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 32).stroke(Theme.surface, lineWidth: 5))
                            .rotationEffect(.degrees(-3))
                            .animation(.easeInOut(duration: 1), value: step)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(done ? "READY" : "KEPT IS READING")
                            .font(Theme.Font.body(12, weight: .bold)).foregroundStyle(Theme.accentHighlight)
                        Text(step >= 2 ? (reel.title ?? ("A reel from " + (reel.author.allSatisfy { $0.isNumber } ? "Instagram User" : reel.author))) : ("A reel from " + (reel.author.allSatisfy { $0.isNumber } ? "Instagram User" : reel.author)))
                            .font(Theme.Font.display(32))

                        VStack(spacing: 0) {
                            ForEach(0..<4, id: \.self) { i in
                                HStack(spacing: 14) {
                                    if i < step {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                                    } else if i == step && !done {
                                        ProgressView().controlSize(.small)
                                    } else {
                                        Circle().stroke(Theme.textSecondary.opacity(0.4)).frame(width: 18, height: 18)
                                    }
                                    Text(stepLabels[i].0)
                                    Spacer()
                                    if i < step { Text(stepLabels[i].1).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary) }
                                }
                                .foregroundStyle(i > step ? Theme.textSecondary : Theme.text)
                                .frame(minHeight: 44)
                            }
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, 24)

                    if done {
                        Button { dismiss() } label: {
                            Text("Open reel").font(Theme.Font.body(16, weight: .semibold))
                                .frame(maxWidth: .infinity).frame(height: 56)
                                .background(Theme.accent, in: Capsule())
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 40)
            }
            .background(Theme.background)
        )
    }
}
