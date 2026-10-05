import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: ReelStore
    @State private var category = "All"
    @State private var searchText = ""
    @State private var openReel: Reel?
    @State private var openProcessing: Reel?
    @State private var openBoard: Board?

    private let categories = ["All", "Food", "Travel", "Fitness", "Home"]
    private let cardHeight: CGFloat = 220

    private var favorites: [Reel] { store.reels.filter { $0.liked } }

    private var filtered: [Reel] {
        store.reels.filter { reel in
            let matchesCategory = category == "All" || reel.category == category
            let matchesSearch = searchText.isEmpty || reel.matches(searchText)
            return matchesCategory && matchesSearch
        }
    }
    private var live: [Reel] { filtered.filter { $0.status.isLive } }
    private var ready: [Reel] { filtered.filter { !$0.status.isLive } }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                if !store.liveReels.isEmpty { liveBanner }
                boardsRow
                if !favorites.isEmpty { favoritesRow }
                categoryChips
                grid
            }
            .padding(.bottom, 100)
        }
        .background(Theme.background)
        .sheet(item: $openReel) { reel in ReelDetailView(reelID: reel.id) }
        .sheet(item: $openProcessing) { reel in ProcessingDetailView(reelID: reel.id) }
        .sheet(item: $openBoard) { board in BoardView(boardID: board.id) }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Text("Kept").font(Theme.Font.display(34, italic: true))
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(Theme.textSecondary)
                TextField("Search \(store.reels.count) reels", text: $searchText)
                    .font(Theme.Font.body(14))
                    .foregroundStyle(Theme.text)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 14).frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(Theme.surface2, in: Capsule())
            Circle().fill(Theme.text).frame(width: 44, height: 44)
                .overlay(Text("D").foregroundStyle(Theme.background).font(Theme.Font.body(15, weight: .semibold)))
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var liveBanner: some View {
        let names = store.liveReels.map { $0.status.label.lowercased() }
        return Button { openProcessing = store.liveReels.first } label: {
            HStack(spacing: 10) {
                HStack(spacing: -12) {
                    ForEach(store.liveReels.prefix(2)) { r in
                        Image(r.coverImageName).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 34, height: 44).clipShape(RoundedRectangle(cornerRadius: 10))
                            .blur(radius: 3).overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.surface, lineWidth: 2))
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Kept is reading \(store.liveReels.count) reel\(store.liveReels.count == 1 ? "" : "s")")
                        .font(Theme.Font.body(14, weight: .semibold))
                    Text(names.joined(separator: " · ")).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                ProgressView().controlSize(.small)
            }
            .padding(10)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .foregroundStyle(Theme.text)
        .padding(.horizontal, 16).padding(.top, 16)
    }

    private var boardsRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Your boards").font(Theme.Font.display(26))
                Spacer()
                Text("Made by Kept").font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 16).padding(.top, 22).padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(store.boards) { board in
                        Button { openBoard = board } label: {
                            BoardTile(board: board, reels: store.reels(in: board.id))
                        }
                        .buttonStyle(PressableCardStyle())
                        .foregroundStyle(Theme.text)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var favoritesRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Favorites").font(Theme.Font.display(26))
                Spacer()
                Text("\(favorites.count) kept").font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 16).padding(.top, 22).padding(.bottom, 10)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(favorites) { reel in
                        Button { openReel = reel } label: {
                            FavoriteTile(reel: reel)
                        }
                        .buttonStyle(PressableCardStyle())
                        .foregroundStyle(Theme.text)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { c in
                    Button { withAnimation(Theme.Spring.snappy) { category = c } } label: {
                        Text(c).font(Theme.Font.body(14, weight: .semibold))
                            .padding(.horizontal, 16).frame(height: 40)
                            .background(c == category ? Theme.text : Theme.surface2, in: Capsule())
                            .foregroundStyle(c == category ? Theme.background : Theme.text)
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
        }
    }

    /// Uniform two-column grid: every card gets the same cover height so the
    /// Library reads as a clean grid rather than a mismatched masonry stack.
    private var grid: some View {
        Group {
            if filtered.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 28))
                        .foregroundStyle(Theme.textSecondary)
                    Text(searchText.isEmpty ? "No reels in this category yet" : "No reels match \"\(searchText)\"")
                        .font(Theme.Font.body(14))
                        .foregroundStyle(Theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 18) {
                    ForEach(live) { reel in
                        Button { openProcessing = reel } label: {
                            LiveProcessingCard(reel: reel, height: cardHeight)
                        }
                        .buttonStyle(PressableCardStyle())
                        .foregroundStyle(Theme.text)
                    }
                    ForEach(ready) { reel in
                        Button { openReel = reel } label: {
                            PinCard(reel: reel, height: cardHeight) {
                                store.toggleLike(reel)
                            }
                        }
                        .buttonStyle(PressableCardStyle())
                        .foregroundStyle(Theme.text)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
    }
}

private struct BoardTile: View {
    let board: Board
    let reels: [Reel]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 3) {
                ForEach(reels.prefix(3)) { r in
                    Image(r.coverImageName).resizable().aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 156, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            Text(board.name).font(Theme.Font.body(15, weight: .semibold))
            Text("\(reels.count) reel\(reels.count == 1 ? "" : "s")").font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
        }
        .frame(width: 156, alignment: .leading)
    }
}

private struct FavoriteTile: View {
    let reel: Reel
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                Image(reel.coverImageName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 132, height: 132)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Image(systemName: "heart.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.accentHighlight)
                    .frame(width: 26, height: 26)
                    .background(.thinMaterial, in: Circle())
                    .padding(6)
            }
            Text(reel.title ?? reel.author)
                .font(Theme.Font.body(13, weight: .semibold))
                .lineLimit(1)
        }
        .frame(width: 132, alignment: .leading)
    }
}

private extension Reel {
    /// Simple client-side search across the fields a user would actually recall:
    /// title, gist, author, category, and any attached place name.
    func matches(_ query: String) -> Bool {
        if (title ?? "").localizedCaseInsensitiveContains(query) { return true }
        if (gist ?? "").localizedCaseInsensitiveContains(query) { return true }
        if author.localizedCaseInsensitiveContains(query) { return true }
        if category.localizedCaseInsensitiveContains(query) { return true }
        if let place, place.name.localizedCaseInsensitiveContains(query) { return true }
        return false
    }
}
