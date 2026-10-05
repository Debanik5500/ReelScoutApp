import SwiftUI

struct BoardView: View {
    @EnvironmentObject var store: ReelStore
    let boardID: UUID
    @State private var tab = "Eat"
    @State private var openReel: Reel?

    private var board: Board? { store.board(boardID) }
    private var reels: [Reel] { store.reels(in: boardID) }
    private let tabs = ["Eat", "See", "Stay"]

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                collage
                VStack(spacing: 10) {
                    Text(board?.name ?? "").font(Theme.Font.display(48))
                    Label("Kept grouped these · \(reels.count) reels", systemImage: "sparkle")
                        .font(Theme.Font.body(13, weight: .semibold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Theme.aiBg, in: Capsule()).foregroundStyle(Theme.aiFg)
                }

                HStack(spacing: 4) {
                    ForEach(tabs, id: \.self) { t in
                        Button { withAnimation(Theme.Spring.snappy) { tab = t } } label: {
                            Text(t).font(Theme.Font.body(14, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 44)
                                .background(tab == t ? Theme.text : .clear, in: Capsule())
                                .foregroundStyle(tab == t ? Theme.background : Theme.text)
                        }
                    }
                }
                .padding(4).background(Theme.surface2, in: Capsule()).padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Text("All \(reels.count) reels").font(Theme.Font.display(26)).padding(.horizontal, 20)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(reels) { reel in
                            Button { openReel = reel } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    Image(reel.coverImageName).resizable().aspectRatio(contentMode: .fill)
                                        .frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    Text(reel.title ?? "").font(Theme.Font.body(14, weight: .semibold)).lineLimit(2)
                                }
                            }
                            .foregroundStyle(Theme.text)
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 20)
        }
        .background(Theme.background)
        .sheet(item: $openReel) { reel in ReelDetailView(reelID: reel.id) }
    }

    private var collage: some View {
        ZStack {
            ForEach(Array(reels.prefix(4).enumerated()), id: \.offset) { i, reel in
                Image(reel.coverImageName).resizable().aspectRatio(contentMode: .fill)
                    .frame(width: i == 0 ? 180 : 130, height: i == 0 ? 250 : 190)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.surface, lineWidth: 4))
                    .rotationEffect(.degrees(i == 0 ? -2 : (i % 2 == 0 ? -9 : 8)))
                    .offset(x: i == 0 ? 0 : (i % 2 == 0 ? -90 : 90), y: i == 0 ? 0 : 10)
                    .shadow(color: .black.opacity(0.18), radius: 20, y: 14)
                    .zIndex(i == 0 ? 2 : 1)
            }
        }
        .frame(height: 260)
    }
}
