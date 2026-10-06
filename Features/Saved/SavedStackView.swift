import SwiftUI

/// "Shuffle your saves": swipe through all ready reels via SwipeStack.
struct SavedStackView: View {
    @EnvironmentObject var store: ReelStore
    @State private var index = 0
    @State private var openReel: Reel?

    private var reels: [Reel] { store.readyReels }

    var body: some View {
        // The blurred backdrop lives in `.background` so its fill-scaled image can never widen the layout
        // (it used to push the counter pill off the left edge of the screen).
        GeometryReader { geo in
        ScrollView {
        VStack(spacing: 20) {
                HStack {
                    Spacer()
                    if !reels.isEmpty {
                        Text("\(min(index, reels.count - 1) + 1) / \(reels.count)")
                            .font(Theme.Font.body(13, weight: .semibold))
                            .monospacedDigit()
                            .fixedSize()
                            .padding(.horizontal, 14).frame(height: 36)
                            .background(Theme.surface, in: Capsule())
                    }
                }
                .padding(.horizontal, 20).padding(.top, 8)

                Text("Shuffle your saves").font(Theme.Font.display(40))

                if !reels.isEmpty {
                    // Sized from the screen so the leaning front card never crosses the left edge.
                    let cardWidth = min(280, geo.size.width - 110)
                    SwipeStack(items: reels, index: $index, cardWidth: cardWidth, cardHeight: cardWidth * 430 / 280,
                               onTapFront: { openReel = $0 }) { reel, isFront in
                        VStack(alignment: .leading, spacing: 0) {
                            ReelCover(reel: reel).aspectRatio(contentMode: .fill)
                                .frame(height: 310).clipped()
                            VStack(alignment: .leading, spacing: 10) {
                                Text(reel.title ?? "").font(Theme.Font.display(24))
                                if isFront {
                                    HStack(spacing: 6) {
                                        if let board = store.board(reel.boardID) {
                                            Text(board.name).font(Theme.Font.body(11, weight: .semibold))
                                                .padding(.horizontal, 9).padding(.vertical, 5)
                                                .background(Theme.aiBg, in: Capsule()).foregroundStyle(Theme.aiFg)
                                        }
                                        if let place = reel.place {
                                            Label(place.name, systemImage: "mappin.circle.fill")
                                                .font(Theme.Font.body(11, weight: .semibold))
                                                .padding(.horizontal, 9).padding(.vertical, 5)
                                                .background(Theme.placeBg, in: Capsule()).foregroundStyle(Theme.placeFg)
                                        }
                                    }
                                }
                            }
                            .padding(14)
                        }
                        .background(Theme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .shadow(color: .black.opacity(0.2), radius: 30, y: 20)
                    }
                    .padding(.top, 10)
                }

                Spacer()

                HStack(spacing: 18) {
                    navButton("chevron.left") { withAnimation(Theme.Spring.standard) { index = (index - 1 + reels.count) % max(reels.count, 1) } }
                    Button { openReel = reels[safe: index] } label: {
                        Image(systemName: "play.fill").font(.system(size: 22))
                            .frame(width: 76, height: 76).background(Theme.accent, in: Circle())
                            .foregroundStyle(.white)
                    }
                    navButton("chevron.right") { withAnimation(Theme.Spring.standard) { index = (index + 1) % max(reels.count, 1) } }
                }
                .padding(.bottom, 30)
        }
        // At least one screen tall so the Spacer keeps the controls at the bottom; pull down to refresh.
        .frame(minHeight: geo.size.height)
        }
        .refreshable { await store.refresh() }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { backdrop }
        .sheet(item: $openReel) { reel in ReelDetailView(reelID: reel.id) }
    }

    private var backdrop: some View {
        ZStack {
            if let current = reels[safe: index] {
                GeometryReader { geo in
                    ReelCover(reel: current)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .blur(radius: 70)
                        .opacity(0.5)
                }
            }
            Theme.background.opacity(0.4)
        }
        .ignoresSafeArea()
    }

    private func navButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold))
                .frame(width: 56, height: 56).background(Theme.surface, in: Circle())
        }
        .foregroundStyle(Theme.text)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
