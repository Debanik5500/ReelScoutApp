import SwiftUI

struct LibraryView: View {
    @EnvironmentObject var store: ReelStore
    @State private var category = "All"
    @State private var platformID: String? = nil // nil == "All"
    @State private var searchText = ""
    @State private var openReel: Reel?
    @State private var openProcessing: Reel?
    @State private var openBoard: Board?
    @State private var showingAdd = false
    @FocusState private var searchFocused: Bool

    private let categories = ["All", "Food", "Travel", "Fitness", "Home", "Tech", "Shopping", "Learning", "Entertainment"]
    private let cardHeight: CGFloat = 220

    private var favorites: [Reel] { store.reels.filter { $0.liked } }

    private var filtered: [Reel] {
        store.reels.filter { reel in
            let matchesCategory = category == "All" || reel.category == category
            let matchesPlatform = platformID == nil || reel.platformID == platformID
            let matchesSearch = searchText.isEmpty || reel.matches(searchText)
            return matchesCategory && matchesPlatform && matchesSearch
        }
    }
    /// Reels still processing, plus failed ones (shown on the same card so they can be retried).
    private var live: [Reel] { filtered.filter { $0.status.isLive || $0.status == .failed } }
    private var ready: [Reel] { filtered.filter { !$0.status.isLive && $0.status != .failed } }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                platformSelector
                if !store.liveReels.isEmpty { liveBanner }
                boardsRow
                if !favorites.isEmpty { favoritesRow }
                categoryChips
                grid
            }
            .padding(.bottom, 100)
        }
        .background(Theme.background)
        .refreshable { await store.refresh() }
        // Keyboard goes away on scroll, and on a tap anywhere (simultaneous, so cards and buttons still work).
        .scrollDismissesKeyboard(.immediately)
        .simultaneousGesture(TapGesture().onEnded { searchFocused = false })
        .overlay(alignment: .bottomTrailing) {
            VStack(alignment: .trailing, spacing: 10) {
                if let quota = store.quota, let remaining = quota.remaining {
                    Button { store.showingPlans = true } label: {
                        Text(remaining == 0 ? "No reels left" : "\(remaining) reel\(remaining == 1 ? "" : "s") left")
                            .font(Theme.Font.body(12, weight: .semibold))
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .background(.thinMaterial, in: Capsule())
                            .foregroundStyle(remaining == 0 ? Theme.accentHighlight : Theme.text)
                    }
                }
                Button { showingAdd = true } label: {
                    Image(systemName: "plus").font(.system(size: 22, weight: .semibold))
                        .frame(width: 60, height: 60)
                        .background(Theme.accent, in: Circle())
                        .foregroundStyle(.white)
                        .shadow(color: Theme.accent.opacity(0.35), radius: 14, y: 8)
                }
                .accessibilityLabel("Add a reel")
            }
            .padding(.trailing, 20).padding(.bottom, 16)
        }
        .sheet(isPresented: $showingAdd) { AddReelView().presentationDetents([.medium]) }
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
                    .focused($searchFocused)
                    .onSubmit { searchFocused = false }
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
            Button { store.showingPlans = true } label: {
                Circle().fill(Theme.text).frame(width: 44, height: 44)
                    .overlay(Text("D").foregroundStyle(Theme.background).font(Theme.Font.body(15, weight: .semibold)))
            }
            .accessibilityLabel("Your plan")
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var liveBanner: some View {
        let names = store.liveReels.map { $0.status.label.lowercased() }.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        return Button { openProcessing = store.liveReels.first } label: {
            HStack(spacing: 10) {
                HStack(spacing: -12) {
                    ForEach(store.liveReels.prefix(2)) { r in
                        ReelCover(reel: r).aspectRatio(contentMode: .fill)
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

    /// Source selector, always shown — "All" plus one segment per entry in
    /// `PlatformRegistry.enabled`, so it reads as "all that are enabled" today
    /// (just Instagram) and grows automatically the moment another platform's
    /// config flips on, no view code changes needed. Styled as a single
    /// segmented pill — distinct from the category chips below it, which are
    /// independent floating capsules — so the two read as separate kinds of
    /// filter at a glance. The selected segment expands to show its label and
    /// fills with that platform's own brand color; the rest collapse to a
    /// plain icon, keeping the whole control compact even as more sources
    /// get added.
    private var platformSelector: some View {
        HStack(spacing: 2) {
            platformSegment(label: "All", icon: "square.grid.2x2.fill", tint: Theme.text, isSelected: platformID == nil) {
                platformID = nil
            }
            ForEach(PlatformRegistry.enabled) { platform in
                platformSegment(label: platform.displayName, icon: platform.icon, tint: platform.color, isSelected: platformID == platform.id) {
                    platformID = platform.id
                }
            }
        }
        .padding(4)
        .background(Theme.surface2, in: Capsule())
        .padding(.horizontal, 16).padding(.top, 14)
    }

    private func platformSegment(label: String, icon: String, tint: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button { withAnimation(Theme.Spring.snappy) { action() } } label: {
            HStack(spacing: isSelected ? 6 : 0) {
                Image(systemName: icon).font(.system(size: 13, weight: .semibold))
                if isSelected {
                    Text(label)
                        .font(Theme.Font.body(13, weight: .semibold))
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .scale(scale: 0.85, anchor: .leading)))
                }
            }
            .padding(.horizontal, isSelected ? 14 : 11)
            .frame(height: 36)
            .background(isSelected ? tint : Color.clear, in: Capsule())
            .foregroundStyle(isSelected ? Theme.background : Theme.textSecondary)
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
                    // One ForEach: when a reel finishes it changes cell kind in place. (Two ForEaches sharing ids
                    // in a lazy grid can leave the old "processing" cell on screen.)
                    ForEach(live + ready) { reel in
                        if reel.status.isLive || reel.status == .failed {
                            Button { openProcessing = reel } label: {
                                LiveProcessingCard(reel: reel, height: cardHeight)
                            }
                            .buttonStyle(PressableCardStyle())
                            .foregroundStyle(Theme.text)
                            .id("live-\(reel.id)")
                        } else {
                            Button { openReel = reel } label: {
                                PinCard(reel: reel, height: cardHeight) {
                                    store.toggleLike(reel)
                                }
                            }
                            .buttonStyle(PressableCardStyle())
                            .foregroundStyle(Theme.text)
                            .id("ready-\(reel.id)")
                        }
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
                    ReelCover(reel: r).aspectRatio(contentMode: .fill)
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
                ReelCover(reel: reel)
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
            Text(reel.title ?? (reel.author.range(of: #"^\d+$"#, options: .regularExpression) == nil ? reel.author : "Instagram User"))
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
