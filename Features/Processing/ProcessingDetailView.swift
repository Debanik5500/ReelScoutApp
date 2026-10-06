import SwiftUI

/// Full-screen live status for one reel: steps ticking off as the backend reports them, findings
/// appearing as chips, cover sharpening as it goes. Driven entirely by the reel's pushed state.
struct ProcessingDetailView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    let reelID: UUID

    private var reel: Reel? { store.reels.first { $0.id == reelID } }

    /// (label, backend step key). The detail text next to a finished step comes from `reel.stepDetails[key]`.
    private let steps: [(label: String, key: String)] = [
        ("Downloading the reel", "downloading"),
        ("Watching and listening", "watching"),
        ("Picking key moments", "keyMoments"),
        ("Finding places and a board", "placesAndBoard"),
    ]

    var body: some View {
        if let reel {
            content(reel)
        } else {
            EmptyView()
        }
    }

    private func content(_ reel: Reel) -> some View {
        let failed = reel.status == .failed
        let done = reel.status == .ready
        let step = done ? 4 : max(reel.status.stepIndex, 0)
        let source = reel.author.isEmpty ? PlatformRegistry.platform(for: reel.platformID).displayName : reel.author
        let title = reel.title ?? "A reel from \(source)"

        return ScrollView {
            VStack(spacing: 28) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                            .frame(width: 44, height: 44).background(Theme.surface, in: Circle())
                    }
                    Spacer()
                    Text(failed ? "Couldn't process" : done ? "Done" : "Step \(min(step + 1, 4)) of 4")
                        .font(Theme.Font.body(13, weight: .semibold))
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(Theme.surface, in: Capsule())
                }
                .padding(.horizontal, 20).padding(.top, 8)
                .foregroundStyle(Theme.text)

                ReelCover(reel: reel).aspectRatio(contentMode: .fill)
                    .frame(width: 220, height: 300)
                    .blur(radius: done ? 0 : max(2, 16 - CGFloat(step) * 4))
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 32).stroke(Theme.surface, lineWidth: 5))
                    .rotationEffect(.degrees(-3))
                    .animation(.easeInOut(duration: 1), value: step)

                VStack(alignment: .leading, spacing: 4) {
                    Text(failed ? "SOMETHING WENT WRONG" : done ? "READY" : "KEPT IS READING")
                        .font(Theme.Font.body(12, weight: .bold)).foregroundStyle(Theme.accentHighlight)
                    Text(title).font(Theme.Font.display(32))

                    if failed {
                        Text("Kept couldn't read this reel. Retry it now, or it will be removed in a couple of minutes.")
                            .font(Theme.Font.body(14)).foregroundStyle(Theme.textSecondary)
                            .padding(.top, 8)
                        if !reel.errorMessage.isEmpty {
                            Text(reel.errorMessage).font(Theme.Font.body(11)).foregroundStyle(Theme.textSecondary.opacity(0.7))
                                .lineLimit(3)
                        }
                    } else {
                        stepList(reel, step: step, done: done)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)

                if !failed && !reel.chips.isEmpty {
                    chipRow(reel.chips)
                }

                if failed {
                    actionButton("Try again") { store.retry(reel); dismiss() }
                    Button("Dismiss") { store.remove(reel); dismiss() }
                        .font(Theme.Font.body(15, weight: .semibold))
                        .foregroundStyle(Theme.textSecondary)
                } else if done {
                    actionButton("Open reel") { dismiss() }
                }
            }
            .padding(.bottom, 40)
        }
        .background(Theme.background)
        .animation(Theme.Spring.standard, value: reel.chips)
    }

    private func stepList(_ reel: Reel, step: Int, done: Bool) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { i, item in
                HStack(spacing: 14) {
                    if i < step {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                    } else if i == step && !done {
                        ProgressView().controlSize(.small)
                    } else {
                        Circle().stroke(Theme.textSecondary.opacity(0.4)).frame(width: 18, height: 18)
                    }
                    Text(item.label)
                    Spacer()
                    if i < step, let detail = reel.stepDetails[item.key], !detail.isEmpty {
                        Text(detail).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                    }
                }
                .foregroundStyle(i > step ? Theme.textSecondary : Theme.text)
                .frame(minHeight: 44)
            }
        }
        .padding(.top, 12)
    }

    private func chipRow(_ chips: [String]) -> some View {
        // Wraps onto several centred lines like the design's findings chips.
        FlowChips(items: chips)
            .padding(.horizontal, 24)
    }

    private func actionButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(Theme.Font.body(16, weight: .semibold))
                .frame(maxWidth: .infinity).frame(height: 56)
                .background(Theme.accent, in: Capsule())
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 20)
    }
}

/// Centred, wrapping row of pill chips (iOS 16+ `Layout`).
private struct FlowChips: View {
    let items: [String]

    var body: some View {
        WrapLayout(spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(Theme.Font.body(14, weight: .semibold))
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .background(Theme.surface, in: Capsule())
                    .foregroundStyle(Theme.text)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

private struct WrapLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(in: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(in: bounds.width, subviews: subviews) {
            var x = bounds.minX + (bounds.width - row.width) / 2
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func rows(in width: CGFloat, subviews: Subviews) -> [Row] {
        var rows = [Row()]
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = rows[rows.count - 1].indices.isEmpty ? size.width : rows[rows.count - 1].width + spacing + size.width
            if needed > width, !rows[rows.count - 1].indices.isEmpty { rows.append(Row()) }
            let last = rows.count - 1
            rows[last].width = rows[last].indices.isEmpty ? size.width : rows[last].width + spacing + size.width
            rows[last].height = max(rows[last].height, size.height)
            rows[last].indices.append(index)
        }
        return rows
    }
}
