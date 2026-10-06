import SwiftUI
import PhotosUI
import UIKit

/// Screenshots, saved web pages and Google results, plus every upcoming event found anywhere in Kept.
struct CapturesView: View {
    @EnvironmentObject var store: ReelStore
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var preparing = false
    @State private var filter: Filter = .all
    @State private var showingAdd = false
    @State private var opened: Reel?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", events = "Events", screenshots = "Screenshots", pages = "Pages"
        var id: String { rawValue }
    }

    private var visible: [Reel] {
        store.captures.filter { reel in
            switch filter {
            case .all: return true
            case .events: return !reel.eventList.isEmpty
            case .screenshots: return reel.kind == "screenshot"
            case .pages: return reel.kind == "webpage"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                addRow
                EventPromptCard()
                comingUp
                chips
                list
            }
            .padding(.bottom, 100)
        }
        .background(Theme.background)
        .refreshable { await store.refresh() }
        .scrollDismissesKeyboard(.immediately)
        .sheet(isPresented: $showingAdd) { AddReelView().presentationDetents([.medium]) }
        .sheet(item: $opened) { reel in
            if reel.isCapture { CaptureDetailView(reelID: reel.id) } else { ReelDetailView(reelID: reel.id) }
        }
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await upload(items) }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Captures").font(Theme.Font.display(34))
            Text("Screenshots, pages and searches. Kept pulls out events so you can add them to your calendar.")
                .font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.horizontal, 16).padding(.top, 8)
    }

    private var addRow: some View {
        HStack(spacing: 10) {
            PhotosPicker(selection: $pickerItems, maxSelectionCount: 10, matching: .screenshots) {
                addButton(preparing ? "Preparing…" : "Add screenshots", icon: "photo.on.rectangle.angled")
            }
            .disabled(preparing)
            Button { showingAdd = true } label: { addButton("Link or text", icon: "link") }
        }
        .padding(.horizontal, 16).padding(.top, 16)
    }

    private func addButton(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(Theme.Font.body(14, weight: .semibold))
            .frame(maxWidth: .infinity).frame(height: 50)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .foregroundStyle(Theme.text)
    }

    @ViewBuilder private var comingUp: some View {
        let upcoming = store.upcomingEvents
        if !upcoming.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Coming up").font(Theme.Font.display(24))
                    Spacer()
                    Text("\(upcoming.count) event\(upcoming.count == 1 ? "" : "s")")
                        .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                }
                ForEach(Array(upcoming.prefix(6)), id: \.event.id) { item in
                    Button { opened = item.reel } label: { UpcomingEventRow(reel: item.reel, event: item.event) }
                        .buttonStyle(PressableCardStyle())
                }
            }
            .padding(.horizontal, 16).padding(.top, 22)
        }
    }

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Filter.allCases) { item in
                    Button { filter = item } label: {
                        Text(item.rawValue).font(Theme.Font.body(13, weight: .semibold))
                            .padding(.horizontal, 16).padding(.vertical, 9)
                            .background(item == filter ? Theme.text : Theme.surface2, in: Capsule())
                            .foregroundStyle(item == filter ? Theme.background : Theme.text)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 22)
    }

    @ViewBuilder private var list: some View {
        if visible.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "photo.on.rectangle.angled").font(.system(size: 30)).foregroundStyle(Theme.textSecondary)
                Text(store.captures.isEmpty ? "Nothing here yet" : "Nothing matches this filter")
                    .font(Theme.Font.body(15, weight: .semibold))
                Text("Share a screenshot, a web page or a Google result to Kept, or add one above.")
                    .font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity).padding(.top, 40).padding(.horizontal, 30)
        } else {
            VStack(spacing: 10) {
                ForEach(visible) { reel in
                    Button { opened = reel } label: { CaptureCard(reel: reel) }
                        .buttonStyle(PressableCardStyle())
                }
            }
            .padding(.horizontal, 16).padding(.top, 14)
        }
    }

    // MARK: - Uploading

    /// Shrinks each picked screenshot (long side 2000 px, JPEG) and sends them as one item.
    private func upload(_ items: [PhotosPickerItem]) async {
        preparing = true
        defer { preparing = false; pickerItems = [] }
        var images: [Data] = []
        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self), let jpeg = Self.prepare(data) else { continue }
            images.append(jpeg)
        }
        store.ingestScreenshots(images)
    }

    static func prepare(_ data: Data, maxSide: CGFloat = 2000) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.jpegData(withCompressionQuality: 0.85) { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
    }
}

/// Icon and label for what a capture turned out to be.
enum CaptureStyle {
    static func icon(for reel: Reel) -> String {
        switch reel.shotType ?? "" {
        case "event": return "calendar"
        case "ticket": return "ticket"
        case "booking": return "suitcase"
        case "schedule": return "list.bullet.rectangle"
        case "message": return "message"
        case "article": return "doc.text"
        case "recipe": return "fork.knife"
        case "product", "listing": return "bag"
        case "receipt": return "receipt"
        case "social_post": return "bubble.left.and.text.bubble.right"
        case "map": return "map"
        default: return reel.kind == "webpage" ? "globe" : "photo"
        }
    }

    static func label(for reel: Reel) -> String {
        guard let type = reel.shotType, !type.isEmpty, type != "other" else {
            return reel.kind == "webpage" ? "Page" : "Screenshot"
        }
        return type.replacingOccurrences(of: "_", with: " ").capitalized
    }

    static func stepText(_ status: ReelStatus) -> String {
        switch status {
        case .queued: return "Waiting"
        case .downloading: return "Uploading"
        case .watching: return "Reading"
        case .keyMoments: return "Understanding"
        case .placesAndBoard: return "Finding events"
        case .ready: return "Ready"
        case .failed: return "Couldn't read this"
        }
    }
}

struct CaptureCard: View {
    let reel: Reel

    private var next: ReelEvent? { reel.eventList.filter { !$0.isPast }.min { $0.start < $1.start } }

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 5) {
                Text(reel.title ?? (reel.status.isLive ? "Reading…" : "Untitled"))
                    .font(Theme.Font.body(15, weight: .semibold)).lineLimit(2).foregroundStyle(Theme.text)
                if reel.status.isLive {
                    ProgressView(value: (Double(max(reel.status.stepIndex, 0)) + reel.progress) / 4).tint(Theme.accent)
                    Text(CaptureStyle.stepText(reel.status)).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                } else if reel.status == .failed {
                    Text(reel.errorMessage.isEmpty ? "Couldn't read this" : reel.errorMessage)
                        .font(Theme.Font.body(12)).foregroundStyle(Theme.accentHighlight).lineLimit(2)
                } else {
                    HStack(spacing: 6) {
                        Text(CaptureStyle.label(for: reel)).font(Theme.Font.body(11, weight: .semibold))
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(Theme.aiBg, in: Capsule()).foregroundStyle(Theme.aiFg)
                        if let next {
                            Label(next.whenText, systemImage: "calendar").font(Theme.Font.body(11, weight: .semibold))
                                .foregroundStyle(Theme.placeFg).lineLimit(1)
                        }
                    }
                    if reel.eventList.count > 1 {
                        Text("\(reel.eventList.count) events").font(Theme.Font.body(11)).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    @ViewBuilder private var thumbnail: some View {
        Group {
            if let url = reel.keyMoments.first?.frameURL ?? reel.coverURL, !url.isEmpty {
                RemoteImage(urlString: url).aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: CaptureStyle.icon(for: reel)).font(.system(size: 22)).foregroundStyle(Theme.textSecondary)
            }
        }
        .frame(width: 64, height: 64)
        .background(Theme.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
