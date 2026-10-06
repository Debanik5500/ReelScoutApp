import SwiftUI
import MapKit

struct ReelDetailView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    let reelID: UUID
    @State private var frameIndex = 0
    @State private var openEdit = false
    @State private var gistExpanded = false
    @State private var showingViewer = false

    /// Key-moment swipe card geometry. Frames are remote photos of arbitrary
    /// aspect ratio, so the card box is pinned here and the image is clipped
    /// into it — the card never grows with its content.
    private let keyCardWidth: CGFloat = 214
    private let keyCardHeight: CGFloat = 318

    private var reel: Reel? { store.reels.first { $0.id == reelID } }

    var body: some View {
        if let reel {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        hero(reel)
                        VStack(alignment: .leading, spacing: 30) {
                            titleBlock(reel).reveal(0.05)
                            if reel.gist != nil { gist(reel).reveal(0.12) }
                            if !reel.keyMoments.isEmpty { keyMoments(reel).reveal(0.18) }
                            if !reel.points.isEmpty { worthRemembering(reel).reveal(0.22) }
                            if !reel.links.isEmpty { linksSection(reel.links).reveal(0.26) }
                            if !reel.products.isEmpty { productsSection(reel.products).reveal(0.28) }
                            if !reel.people.isEmpty { peopleSection(reel.people).reveal(0.30) }
                            if !reel.places.isEmpty { locationCard(reel.places).reveal(0.32) }
                            if let board = store.board(reel.boardID) { boardLink(board, reel: reel).reveal(0.34) }
                            if !reel.sources.isEmpty { sourcesSection(reel.sources).reveal(0.36) }
                            originalButton(reel).reveal(0.38)
                        }
                        .padding(.horizontal, 20).padding(.top, 22).padding(.bottom, 40)
                    }
                }
                .background(Theme.background)
                .sheet(isPresented: $openEdit) { EditReelView(reelID: reelID) }
                .fullScreenCover(isPresented: $showingViewer) {
                    KeyMomentViewer(moments: reel.keyMoments, index: $frameIndex)
                }
            }
        } else {
            // The reel was deleted (or never existed): close the sheet instead of showing a blank page.
            Color.clear.onAppear { dismiss() }
        }
    }

    // MARK: - Hero

    private func hero(_ reel: Reel) -> some View {
        // The illustration lives in an overlay so its fill-scaled size can never widen the layout.
        Color.clear
            .frame(height: 400)
            .overlay { ReelCover(reel: reel).aspectRatio(contentMode: .fill) }
            .overlay {
                LinearGradient(colors: [.black.opacity(0.22), .clear, .black.opacity(0.18)],
                               startPoint: .top, endPoint: .bottom)
            }
            .overlay(alignment: .top) {
                HStack(spacing: 10) {
                    circleButton("chevron.left") { dismiss() }
                    Spacer()
                    circleButton(reel.liked ? "heart.fill" : "heart",
                                 tint: reel.liked ? Theme.accentHighlight : Theme.text) { store.toggleLike(reel) }
                    circleButton("pencil") { openEdit = true }
                }
                .padding(.horizontal, 12).padding(.top, 50)
            }
            .overlay {
                if let url = URL(string: reel.sourceURL), !reel.sourceURL.isEmpty {
                    Link(destination: url) {
                        Image(systemName: "play.fill").font(.system(size: 22))
                            .foregroundStyle(Theme.text)
                            .frame(width: 68, height: 68)
                            .background(.regularMaterial, in: Circle())
                            .shadow(color: .black.opacity(0.18), radius: 14, y: 6)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .shadow(color: .black.opacity(0.12), radius: 24, y: 14)
            .padding(12)
    }

    private func circleButton(_ icon: String, tint: Color = Theme.text, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(tint)
                .frame(width: 44, height: 44).background(.thinMaterial, in: Circle())
        }
    }

    // MARK: - Title, source, facts

    private func titleBlock(_ reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(reel.title ?? "Untitled reel")
                .font(Theme.Font.display(38))
                .lineSpacing(-2)
                .fixedSize(horizontal: false, vertical: true)
            sourceCard(reel)
            factChips(reel)
        }
    }

    private func handle(_ reel: Reel) -> String? {
        let author = reel.author.trimmingCharacters(in: .whitespaces)
        guard !author.isEmpty, author != "Instagram User", !author.allSatisfy({ $0.isNumber }) else { return nil }
        return author
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private func savedText(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Saved today" }
        return "Saved " + Self.relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    /// Who posted it, where it is from and when it was saved, with a clear way back to the original.
    private func sourceCard(_ reel: Reel) -> some View {
        let platform = PlatformRegistry.platform(for: reel.platformID)
        let name = handle(reel) ?? platform.displayName
        return HStack(spacing: 12) {
            ZStack {
                Circle().fill(platform.color.opacity(0.14))
                if let handle = handle(reel) {
                    Text(String(handle.drop(while: { $0 == "@" }).prefix(1)).uppercased())
                        .font(Theme.Font.body(16, weight: .bold)).foregroundStyle(platform.color)
                } else {
                    Image(systemName: platform.icon).font(.system(size: 16, weight: .semibold)).foregroundStyle(platform.color)
                }
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(Theme.Font.body(15, weight: .semibold)).lineLimit(1)
                HStack(spacing: 5) {
                    Image(systemName: platform.icon).font(.system(size: 10, weight: .semibold))
                    Text("\(platform.displayName) · \(savedText(reel.savedAt))").lineLimit(1)
                }
                .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)

            if let url = URL(string: reel.sourceURL), !reel.sourceURL.isEmpty {
                Link(destination: url) {
                    HStack(spacing: 4) {
                        Text("Original")
                        Image(systemName: "arrow.up.right").font(.system(size: 10, weight: .bold))
                    }
                    .font(Theme.Font.body(13, weight: .semibold))
                    .padding(.horizontal, 14).frame(height: 36)
                    .background(Theme.surface2, in: Capsule())
                    .foregroundStyle(Theme.text)
                }
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    /// One-glance facts. A chip appears only when the reel actually has that fact.
    private func factChips(_ reel: Reel) -> some View {
        var chips: [(icon: String, text: String, fg: Color, bg: Color)] = []
        if !reel.category.isEmpty { chips.append(("tag.fill", reel.category, Theme.aiFg, Theme.aiBg)) }
        if reel.places.count > 1 {
            chips.append(("mappin.and.ellipse", "\(reel.places.count) places", Theme.placeFg, Theme.placeBg))
        } else if let place = reel.place {
            chips.append(("mappin.circle.fill", place.name, Theme.placeFg, Theme.placeBg))
        }
        if reel.duration != "0:00", !reel.duration.isEmpty {
            chips.append(("clock.fill", reel.duration, Theme.textSecondary, Theme.surface2))
        }
        if !reel.keyMoments.isEmpty {
            chips.append(("photo.stack.fill", "\(reel.keyMoments.count) moments", Theme.textSecondary, Theme.surface2))
        }
        if !reel.links.isEmpty {
            chips.append(("link", "\(reel.links.count) link\(reel.links.count == 1 ? "" : "s")", Theme.textSecondary, Theme.surface2))
        }
        return Group {
            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                            Label(chip.text, systemImage: chip.icon)
                                .font(Theme.Font.body(12, weight: .semibold))
                                .lineLimit(1)
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(chip.bg, in: Capsule())
                                .foregroundStyle(chip.fg)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Gist

    private func gist(_ reel: Reel) -> some View {
        let text = reel.gist ?? ""
        let isLong = text.count > 170
        return VStack(alignment: .leading, spacing: 8) {
            Label("The gist", systemImage: "sparkle")
                .font(Theme.Font.body(12, weight: .semibold)).foregroundStyle(Theme.aiFg)
            Text(text)
                .font(Theme.Font.display(19))
                .lineSpacing(3)
                .lineLimit(gistExpanded ? nil : 4)
                .fixedSize(horizontal: false, vertical: true)
            if isLong {
                Button(gistExpanded ? "Show less" : "Read more") {
                    withAnimation(Theme.Spring.snappy) { gistExpanded.toggle() }
                }
                .font(Theme.Font.body(12, weight: .semibold)).foregroundStyle(Theme.aiFg)
            }
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.aiBg, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Section scaffolding

    private func sectionHeader(_ title: String, trailing: AnyView? = nil) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(Theme.Font.display(26))
            Spacer()
            if let trailing { trailing }
        }
    }

    private func secondaryLabel(_ text: String) -> AnyView {
        AnyView(Text(text).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary))
    }

    // MARK: - Key moments

    private func keyMoments(_ reel: Reel) -> some View {
        let count = reel.keyMoments.count
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Key moments", trailing: secondaryLabel("Tap to expand · \(min(frameIndex, count - 1) + 1) of \(count)"))
            SwipeStack(items: reel.keyMoments, index: $frameIndex, cardWidth: keyCardWidth, cardHeight: keyCardHeight,
                       onTapFront: { _ in showingViewer = true }) { frame, isFront in
                ZStack(alignment: .bottomLeading) {
                    ZStack {
                        if let frameURL = frame.frameURL, !frameURL.isEmpty {
                            RemoteImage(urlString: frameURL)
                                .aspectRatio(contentMode: .fill)
                        } else {
                            Image.cover(frame.imageName).resizable().aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(width: keyCardWidth, height: keyCardHeight)
                    .clipped()
                    if isFront {
                        LinearGradient(colors: [.black.opacity(0.78), .clear], startPoint: .bottom, endPoint: .center)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(frame.timestamp).font(Theme.Font.body(11, weight: .bold))
                                .padding(.horizontal, 8).padding(.vertical, 4).background(.white, in: Capsule()).foregroundStyle(.black)
                            Text(frame.label).font(Theme.Font.display(22)).foregroundStyle(.white)
                            if !frame.note.isEmpty {
                                Text(frame.note).font(Theme.Font.body(13)).foregroundStyle(.white.opacity(0.85))
                            }
                        }
                        .padding(14)
                    }
                }
                .frame(width: keyCardWidth, height: keyCardHeight)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(.white, lineWidth: 4))
                .shadow(color: .black.opacity(0.16), radius: 14, y: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)

            // (images are warmed when the section appears, see .task below)
            // Page dots, like the design.
            HStack(spacing: 6) {
                ForEach(0..<count, id: \.self) { i in
                    Capsule()
                        .fill(i == min(frameIndex, count - 1) ? Theme.text : Theme.textSecondary.opacity(0.3))
                        .frame(width: i == min(frameIndex, count - 1) ? 20 : 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(Theme.Spring.snappy, value: frameIndex)
        }
        .task(id: reel.keyMoments.count) { await ReelAPIClient.shared.prefetchImages(for: reel) }
    }

    // MARK: - Worth remembering

    private func worthRemembering(_ reel: Reel) -> some View {
        let doneCount = reel.points.filter(\.done).count
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Worth remembering", trailing: AnyView(
                HStack(spacing: 12) {
                    Text("\(doneCount) of \(reel.points.count)").font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
                    Button("Edit") { openEdit = true }.font(Theme.Font.body(13, weight: .semibold))
                }
            ))
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
                            Text(point.text).font(Theme.Font.body(15)).multilineTextAlignment(.leading)
                                .strikethrough(point.done).foregroundStyle(point.done ? Theme.textSecondary : Theme.text)
                            Spacer()
                        }
                        .padding(14)
                        .background(point.done ? Theme.placeBg : Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Links, products, people, sources

    private func host(_ urlString: String) -> String {
        let host = URL(string: urlString)?.host ?? urlString
        return host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
    }

    private func linksSection(_ links: [ReelLink]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Links", trailing: secondaryLabel("\(links.count)"))
            VStack(spacing: 8) {
                ForEach(links) { link in
                    if let url = URL(string: link.url) {
                        Link(destination: url) {
                            rowCard(icon: link.kind == "github_repo" ? "chevron.left.forwardslash.chevron.right" : "globe",
                                    tileFg: Theme.aiFg, tileBg: Theme.aiBg,
                                    title: link.label,
                                    subtitle: link.note ?? host(link.url), trailingIcon: "arrow.up.right")
                        }
                    }
                }
            }
        }
    }

    private func productsSection(_ products: [ReelProduct]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Products", trailing: secondaryLabel("\(products.count)"))
            VStack(spacing: 8) {
                ForEach(products) { product in
                    let subtitle = product.brand == product.name ? "" : product.brand
                    if let url = URL(string: product.url), !product.url.isEmpty {
                        Link(destination: url) {
                            rowCard(icon: "bag.fill", tileFg: Theme.accent, tileBg: Theme.accent.opacity(0.12),
                                    title: product.name, subtitle: subtitle, trailingIcon: "arrow.up.right")
                        }
                    } else {
                        rowCard(icon: "bag.fill", tileFg: Theme.accent, tileBg: Theme.accent.opacity(0.12),
                                title: product.name, subtitle: subtitle, trailingIcon: nil)
                    }
                }
            }
        }
    }

    private func peopleSection(_ people: [ReelPerson]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("People")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(people) { person in
                        HStack(spacing: 10) {
                            Circle().fill(Theme.placeBg).frame(width: 38, height: 38)
                                .overlay(Text(String(person.name.prefix(1)).uppercased())
                                    .font(Theme.Font.body(15, weight: .bold)).foregroundStyle(Theme.placeFg))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(person.name).font(Theme.Font.body(14, weight: .semibold)).lineLimit(1)
                                if !person.role.isEmpty {
                                    Text(person.role).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical, 8).padding(.leading, 8).padding(.trailing, 16)
                        .background(Theme.surface, in: Capsule())
                    }
                }
            }
        }
    }

    private func sourcesSection(_ sources: [ReelSource]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SOURCES").font(Theme.Font.body(11, weight: .bold)).foregroundStyle(Theme.textSecondary)
            ForEach(sources) { source in
                if let url = URL(string: source.url) {
                    Link(destination: url) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.text").font(.system(size: 11))
                            Text(source.title).lineLimit(1)
                            Spacer()
                            Text(host(source.url)).lineLimit(1)
                        }
                        .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    /// Shared row: tinted icon tile, title, optional subtitle and an optional trailing arrow.
    private func rowCard(icon: String, tileFg: Color, tileBg: Color, title: String, subtitle: String,
                         trailingIcon: String?) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tileBg).frame(width: 44, height: 44)
                .overlay(Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(tileFg))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Font.body(15, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary).lineLimit(2)
                }
            }
            Spacer()
            if let trailingIcon {
                Image(systemName: trailingIcon).font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    // MARK: - Location, board, original

    private func locationCard(_ places: [ReelPlace]) -> some View {
        let coordinates = PlaceSpread.coordinates(for: places)
        let pins: [(number: Int, place: ReelPlace, coordinate: CLLocationCoordinate2D)] =
            places.enumerated().compactMap { index, place in
                coordinates[place.id].map { (index + 1, place, $0) }
            }
        return VStack(alignment: .leading, spacing: 12) {
            sectionHeader(places.count > 1 ? "Where they are" : "Where it is",
                          trailing: places.count > 1 ? secondaryLabel("\(places.count) places") : nil)
            VStack(alignment: .leading, spacing: 0) {
                // Pins only for places the backend could locate; never a placeholder location.
                if !coordinates.isEmpty {
                    Map(initialPosition: .automatic) {
                        ForEach(pins, id: \.place.id) { pin in
                            Marker(places.count > 1 ? "\(pin.number). \(pin.place.name)" : pin.place.name,
                                   coordinate: pin.coordinate)
                        }
                    }
                    .frame(height: 190)
                }
                VStack(spacing: 0) {
                    ForEach(Array(places.enumerated()), id: \.element.id) { index, place in
                        if index > 0 { Divider().padding(.leading, 16) }
                        placeRow(place, number: places.count > 1 ? index + 1 : nil)
                    }
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        }
    }

    private func placeRow(_ place: ReelPlace, number: Int?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            if let number {
                Text("\(number)").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 24, height: 24).background(Theme.accent, in: Circle()).padding(.top, 1)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(place.name).font(Theme.Font.body(16, weight: .semibold))
                    if place.isApproximate {
                        Text("Approximate").font(Theme.Font.body(10, weight: .bold))
                            .padding(.horizontal, 7).padding(.vertical, 3)
                            .background(Theme.surface2, in: Capsule()).foregroundStyle(Theme.textSecondary)
                    }
                }
                if !place.subtitle.isEmpty {
                    Text(place.subtitle).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
                }
                if let note = place.note, place.isApproximate {
                    Text(note).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let url = URL(string: place.mapURL), !place.mapURL.isEmpty {
                Link(destination: url) {
                    Text("Directions").font(Theme.Font.body(13, weight: .semibold))
                        .padding(.horizontal, 14).frame(height: 38)
                        .background(Theme.text, in: Capsule()).foregroundStyle(Theme.background)
                }
            }
        }
        .padding(16)
    }

    private func boardLink(_ board: Board, reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("On your board")
            NavigationLink {
                BoardView(boardID: board.id)
            } label: {
                HStack(spacing: 14) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 2) {
                        ForEach(store.reels(in: board.id).prefix(4)) { r in
                            ReelCover(reel: r).aspectRatio(contentMode: .fill)
                        }
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
        }
    }

    private func originalButton(_ reel: Reel) -> some View {
        let platform = PlatformRegistry.platform(for: reel.platformID)
        return Group {
            if let url = URL(string: reel.sourceURL), !reel.sourceURL.isEmpty {
                Link(destination: url) {
                    Label("Watch on \(platform.displayName)", systemImage: "play.fill")
                        .font(Theme.Font.body(16, weight: .semibold))
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Theme.accent, in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
    }
}

/// Fades and lifts a section in shortly after the page opens; the delay staggers the sections.
private struct Reveal: ViewModifier {
    let delay: Double
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 16)
            .onAppear { withAnimation(.easeOut(duration: 0.5).delay(delay)) { shown = true } }
    }
}

private extension View {
    func reveal(_ delay: Double = 0) -> some View { modifier(Reveal(delay: delay)) }
}
