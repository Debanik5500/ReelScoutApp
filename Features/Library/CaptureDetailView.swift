import SwiftUI

/// One screenshot or saved page: what it is, its events (with calendar and reminders), places, links and facts.
struct CaptureDetailView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    let reelID: UUID
    @State private var imageIndex = 0
    @State private var showingViewer = false
    @State private var confirmDelete = false

    private var reel: Reel? { store.reels.first { $0.id == reelID } }

    var body: some View {
        if let reel {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    topBar(reel)
                    if reel.status.isLive { progressBlock(reel) }
                    else if reel.status == .failed { failedBlock(reel) }
                    else { content(reel) }
                }
                .padding(.horizontal, 20).padding(.bottom, 40)
            }
            .background(Theme.background)
            .fullScreenCover(isPresented: $showingViewer) {
                KeyMomentViewer(moments: reel.keyMoments, index: $imageIndex)
            }
            .confirmationDialog("Delete this from Kept?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) { store.remove(reel); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Its reminders are removed too. Calendar entries you added stay in your calendar.")
            }
        } else {
            // Deleted (or never existed): close instead of showing a blank page.
            Color.clear.onAppear { dismiss() }
        }
    }

    private func topBar(_ reel: Reel) -> some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44).background(Theme.surface, in: Circle())
            }
            Spacer()
            Button { confirmDelete = true } label: {
                Image(systemName: "trash").font(.system(size: 15, weight: .semibold))
                    .frame(width: 44, height: 44).background(Theme.surface, in: Circle())
            }
        }
        .foregroundStyle(Theme.text).padding(.top, 8)
    }

    // MARK: - States

    private func progressBlock(_ reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(CaptureStyle.stepText(reel.status).uppercased())
                .font(Theme.Font.body(12, weight: .bold)).foregroundStyle(Theme.accentHighlight)
            Text(reel.title ?? "Kept is reading this").font(Theme.Font.display(30))
            ProgressView(value: (Double(max(reel.status.stepIndex, 0)) + reel.progress) / 4).tint(Theme.accent)
            Text("This usually takes under a minute. You can leave this screen.")
                .font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 30)
    }

    private func failedBlock(_ reel: Reel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COULDN'T READ THIS").font(Theme.Font.body(12, weight: .bold)).foregroundStyle(Theme.accentHighlight)
            Text(reel.errorMessage.isEmpty ? "Something went wrong." : reel.errorMessage).font(Theme.Font.body(15))
            Button {
                store.retry(reel); dismiss()
            } label: {
                Text(reel.sourceURL.isEmpty ? "Remove" : "Try again").font(Theme.Font.body(15, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Theme.accent, in: Capsule()).foregroundStyle(.white)
            }
            if reel.sourceURL.isEmpty {
                Text("Screenshots aren't kept after a failed upload. Add them again from Captures.")
                    .font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(.top, 30)
    }

    // MARK: - Ready

    @ViewBuilder private func content(_ reel: Reel) -> some View {
        if reel.kind == "screenshot", !reel.keyMoments.isEmpty { imagePager(reel) }

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(CaptureStyle.label(for: reel), systemImage: CaptureStyle.icon(for: reel))
                    .font(Theme.Font.body(12, weight: .semibold))
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Theme.aiBg, in: Capsule()).foregroundStyle(Theme.aiFg)
                if reel.kind == "webpage", !reel.author.isEmpty {
                    Text(reel.author).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                }
            }
            Text(reel.title ?? "Untitled").font(Theme.Font.display(34)).fixedSize(horizontal: false, vertical: true)
            if let summary = reel.gist {
                Text(summary).font(Theme.Font.body(15)).foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }

        if reel.kind == "webpage", let url = URL(string: reel.sourceURL), !reel.sourceURL.isEmpty {
            Link(destination: url) {
                Label("Open the page", systemImage: "arrow.up.right.square").font(Theme.Font.body(14, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(Theme.surface, in: Capsule()).foregroundStyle(Theme.text)
            }
        }

        if !reel.eventList.isEmpty {
            section(reel.eventList.count > 1 ? "Events" : "Event", trailing: reel.eventList.count > 1 ? "\(reel.eventList.count)" : nil) {
                ForEach(reel.eventList) { event in EventCard(reelID: reel.id, event: event) }
            }
        }

        if !reel.places.isEmpty {
            section("Places", trailing: nil) {
                ForEach(reel.places) { place in placeRow(place) }
            }
        }

        if !reel.links.isEmpty {
            section("Links", trailing: nil) {
                ForEach(reel.links) { link in
                    if let url = URL(string: link.url) {
                        Link(destination: url) { row(icon: "globe", title: link.label, subtitle: link.note ?? link.url) }
                    }
                }
            }
        }

        if !reel.points.isEmpty {
            section("Worth remembering", trailing: nil) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(reel.points) { point in
                        Text("• " + point.text).font(Theme.Font.body(14)).fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
        }
    }

    private func imagePager(_ reel: Reel) -> some View {
        VStack(spacing: 8) {
            TabView(selection: $imageIndex) {
                ForEach(Array(reel.keyMoments.enumerated()), id: \.element.id) { index, moment in
                    Group {
                        if let url = moment.frameURL, !url.isEmpty {
                            RemoteImage(urlString: url).aspectRatio(contentMode: .fit)
                        } else {
                            Color.clear
                        }
                    }
                    .frame(maxWidth: .infinity).tag(index)
                    .onTapGesture { showingViewer = true }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: reel.keyMoments.count > 1 ? .automatic : .never))
            .frame(height: 380)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            Text("Tap to enlarge").font(Theme.Font.body(11)).foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: - Pieces

    private func section<Content: View>(_ title: String, trailing: String?, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(Theme.Font.display(24))
                Spacer()
                if let trailing { Text(trailing).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary) }
            }
            content()
        }
    }

    private func placeRow(_ place: ReelPlace) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "mappin.circle.fill").font(.system(size: 20)).foregroundStyle(Theme.placeFg)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name).font(Theme.Font.body(15, weight: .semibold))
                if !place.subtitle.isEmpty {
                    Text(place.subtitle).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
            if let url = URL(string: place.mapURL), !place.mapURL.isEmpty {
                Link(destination: url) {
                    Text("Directions").font(Theme.Font.body(12, weight: .semibold))
                        .padding(.horizontal, 12).frame(height: 34)
                        .background(Theme.text, in: Capsule()).foregroundStyle(Theme.background)
                }
            }
        }
        .padding(14).background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func row(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Theme.aiBg).frame(width: 40, height: 40)
                .overlay(Image(systemName: icon).foregroundStyle(Theme.aiFg))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.Font.body(15, weight: .semibold)).foregroundStyle(Theme.text).lineLimit(1)
                Text(subtitle).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary).lineLimit(2)
            }
            Spacer()
            Image(systemName: "arrow.up.right").font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textSecondary)
        }
        .padding(12).background(Theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
