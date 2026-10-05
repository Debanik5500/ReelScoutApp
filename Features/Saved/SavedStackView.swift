import SwiftUI

/// "Shuffle your saves": swipe through all ready reels via SwipeStack.
struct SavedStackView: View {
    @EnvironmentObject var store: ReelStore
    @State private var index = 0
    @State private var openReel: Reel?

    private var reels: [Reel] { store.readyReels }

    var body: some View {
        ZStack {
            if let current = reels[safe: index] {
                Image(current.coverImageName).resizable().aspectRatio(contentMode: .fill)
                    .blur(radius: 70).opacity(0.5).ignoresSafeArea()
            }
            Theme.background.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Text("\(index + 1) / \(reels.count)")
                        .font(Theme.Font.body(13, weight: .semibold))
                        .padding(.horizontal, 14).frame(height: 36)
                        .background(Theme.surface, in: Capsule())
                    Spacer()
                }
                .padding(.horizontal, 20).padding(.top, 8)

                Text("Shuffle your saves").font(Theme.Font.display(40))

                if !reels.isEmpty {
                    SwipeStack(items: reels, index: $index, cardWidth: 280, cardHeight: 430) { reel, isFront in
                        VStack(alignment: .leading, spacing: 0) {
                            Image.cover(reel.coverImageName).resizable().aspectRatio(contentMode: .fill)
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
        }
        .sheet(item: $openReel) { reel in ReelDetailView(reelID: reel.id) }
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
