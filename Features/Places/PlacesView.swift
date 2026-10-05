import SwiftUI
import MapKit

struct PlacesView: View {
    @EnvironmentObject var store: ReelStore
    @State private var selected: Reel?
    @State private var cameraPosition: MapCameraPosition = .automatic

    private var placedReels: [Reel] { store.reels.filter { $0.place != nil && !$0.status.isLive } }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(placedReels) { reel in
                    Annotation(reel.place?.name ?? "", coordinate: CLLocationCoordinate2D(
                        latitude: 35.69 + Double(reel.id.hashValue % 100) / 5000,
                        longitude: 139.70 + Double(reel.id.hashValue % 70) / 5000
                    )) {
                        Button { withAnimation(Theme.Spring.snappy) { selected = reel } } label: {
                            Image.cover(reel.coverImageName).resizable().aspectRatio(contentMode: .fill)
                                    .frame(width: selected?.id == reel.id ? 44 : 36, height: selected?.id == reel.id ? 44 : 36)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(selected?.id == reel.id ? Theme.accent : Theme.surface, lineWidth: 3))
                                    .shadow(radius: 6)
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule().fill(Theme.textSecondary.opacity(0.3)).frame(width: 40, height: 5).padding(.vertical, 12)
                if let reel = selected ?? placedReels.first, let place = reel.place {
                    HStack(spacing: 14) {
                        Image.cover(reel.coverImageName).resizable().aspectRatio(contentMode: .fill)
                            .frame(width: 92, height: 120).clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        VStack(alignment: .leading, spacing: 6) {
                            Text(place.name).font(Theme.Font.display(26))
                            Text(place.subtitle).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
                            if let board = store.board(reel.boardID) {
                                Text("From \"\(reel.title ?? "")\"").font(Theme.Font.body(13, weight: .semibold)).foregroundStyle(Theme.aiFg)
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 10) {
                        if let url = URL(string: place.mapURL) {
                            Link(destination: url) {
                                Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                    .font(Theme.Font.body(15, weight: .semibold))
                                    .frame(maxWidth: .infinity).frame(height: 50)
                                    .background(Theme.accent, in: Capsule()).foregroundStyle(.white)
                            }
                        }
                        NavigationLink {
                            ReelDetailView(reelID: reel.id)
                        } label: {
                            Text("Watch reel").font(Theme.Font.body(15, weight: .semibold))
                                .frame(maxWidth: .infinity).frame(height: 50)
                                .background(Theme.surface2, in: Capsule()).foregroundStyle(Theme.text)
                        }
                    }
                    .padding(16)
                }
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
            .padding(8)
        }
    }
}
