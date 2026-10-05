import SwiftUI
import MapKit

struct ReelDetailView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    let reelID: UUID
    @State private var frameIndex = 0
    @State private var openEdit = false

    private var reel: Reel? { store.reels.first { $0.id == reelID } }

    var body: some View {
        if let reel {
            NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    hero(reel)
                    VStack(alignment: .leading, spacing: 34) {
                        titleBlock(reel)
                        gist(reel)
                        if !reel.keyMoments.isEmpty { keyMoments(reel) }
                        if !reel.points.isEmpty { worthRemembering(reel) }
                        if let place = reel.place { locationCard(place) }
                        if let board = store.board(reel.boardID) { boardLink(board, reel: reel) }
                    }
                    .padding(.horizontal, 20).padding(.top, 22)
                }
            }
            .background(Theme.background)
            .sheet(isPresented: $openEdit) { EditReelView(reelID: reelID) }
            }
        } else {
            EmptyView()
        }
    }

    private func hero(_ reel: Reel) -> some View {
        ZStack(alignment: .topTrailing) {
            Image(reel.coverImageName).resizable().aspectRatio(contentMode: .fill)
                .frame(height: 480).clipped()
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44).background(.thinMaterial, in: Circle())
                }
                Spacer()
                Button { store.toggleLike(reel) } label: {
                    Image(systemName: reel.liked ? "heart.fill" : "heart")
                        .foregroundStyle(reel.liked ? Theme.accentHighlight : Theme.text)
                        .frame(width: 44, height: 44).background(.thinMaterial, in: Circle())
                }
                Button { openEdit = true } label: {
                    Image(systemName: "pencil").frame(width: 44, height: 44).background(.thinMaterial, in: Circle())
                }
            }
            .padding(.horizontal, 12).padding(.top, 50)
        }
        .foregroundStyle(Theme.text)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .padding(12)
    }

    private func titleBlock(_ reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(reel.title ?? "").font(Theme.Font.display(40))
            HStack {
                Circle().fill(Color.orange).frame(width: 32, height: 32)
                    .overlay(Text(String(reel.author.dropFirst().prefix(1)).uppercased()).font(Theme.Font.body(13, weight: .bold)))
                VStack(alignment: .leading) {
                    Text(reel.author).font(Theme.Font.body(14, weight: .semibold))
                    Text("Instagram · saved today").font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
            }
        }
    }

    private func gist(_ reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("The gist", systemImage: "sparkle").font(Theme.Font.body(13, weight: .semibold)).foregroundStyle(Theme.aiFg)
            Text(reel.gist ?? "").font(Theme.Font.display(24))
        }
        .padding(20).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.aiBg, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func keyMoments(_ reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Key moments").font(Theme.Font.display(28))
                Spacer()
                Text("Swipe · \(frameIndex + 1) of \(reel.keyMoments.count)").font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
            }
            SwipeStack(items: reel.keyMoments, index: $frameIndex, cardWidth: 196, cardHeight: 290) { frame, isFront in
                ZStack(alignment: .bottomLeading) {
                    Image(frame.imageName).resizable().aspectRatio(contentMode: .fill)
                    if isFront {
                        LinearGradient(colors: [.black.opacity(0.75), .clear], startPoint: .bottom, endPoint: .center)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(frame.timestamp).font(Theme.Font.body(11, weight: .bold))
                                .padding(.horizontal, 8).padding(.vertical, 4).background(.white, in: Capsule()).foregroundStyle(.black)
                            Text(frame.label).font(Theme.Font.display(22)).foregroundStyle(.white)
                            Text(frame.note).font(Theme.Font.body(13)).foregroundStyle(.white.opacity(0.85))
                        }
                        .padding(12)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func worthRemembering(_ reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Worth remembering").font(Theme.Font.display(28))
                Spacer()
                Button("Edit") { openEdit = true }.font(Theme.Font.body(13, weight: .semibold))
            }
            VStack(spacing: 8) {
                ForEach(reel.points) { point in
                    Button { store.togglePoint(reel, point: point) } label: {
                        HStack(alignment: .top, spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8).stroke(point.done ? Theme.success : Theme.textSecondary.opacity(0.4), lineWidth: 2)
                                    .background(point.done ? Theme.success : .clear)
                                if point.done { Image(systemName: "checkmark").font(.system(size: 11, weight: .black)).foregroundStyle(.white) }
                            }
                            .frame(width: 24, height: 24).clipShape(RoundedRectangle(cornerRadius: 8))
                            Text(point.text).strikethrough(point.done).foregroundStyle(point.done ? Theme.textSecondary : Theme.text)
                            Spacer()
                        }
                        .padding(14)
                        .background(point.done ? Theme.placeBg : Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                }
            }
        }
    }

    private func locationCard(_ place: ReelPlace) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Where it is").font(Theme.Font.display(28)).padding(.bottom, 14)
            Map(initialPosition: .automatic) {
                Marker(place.name, coordinate: CLLocationCoordinate2D(latitude: 35.6938, longitude: 139.7034))
            }
            .frame(height: 160)
            HStack {
                VStack(alignment: .leading) {
                    Text(place.name).font(Theme.Font.body(16, weight: .semibold))
                    Text(place.subtitle).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                if let url = URL(string: place.mapURL) {
                    Link(destination: url) {
                        Text("Directions").font(Theme.Font.body(14, weight: .semibold))
                            .padding(.horizontal, 18).frame(height: 44)
                            .background(Theme.text, in: Capsule()).foregroundStyle(Theme.background)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func boardLink(_ board: Board, reel: Reel) -> some View {
        NavigationLink {
            BoardView(boardID: board.id)
        } label: {
            HStack(spacing: 14) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                    ForEach(store.reels(in: board.id).prefix(4)) { r in Image(r.coverImageName).resizable().aspectRatio(contentMode: .fill) }
                }
                .frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                VStack(alignment: .leading) {
                    Text(board.name).font(Theme.Font.body(16, weight: .semibold))
                    Text("Kept added it here · \(store.reels(in: board.id).count) reels").font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
            }
            .padding(10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        }
        .foregroundStyle(Theme.text)
        .padding(.bottom, 20)
    }
}
