import SwiftUI
import MapKit

/// Every saved reel that has places. The map shows where they are; the panel lists them grouped by reel,
/// so a list reel ("5 places near Siliguri") reads as one group instead of five unrelated rows.
struct PlacesView: View {
    @EnvironmentObject var store: ReelStore
    @State private var selectedPlaceID: UUID?
    @State private var cameraPosition: MapCameraPosition = .automatic
    /// The panel can be pulled down so the whole map is free to explore.
    @State private var expanded = true
    @State private var listAtTop = true
    /// Whether the current drag on the list began with the list already at its top (so it cannot be a scroll).
    @State private var dragStartedAtTop: Bool?
    @State private var collapsedGroups: Set<UUID> = []

    private struct PlaceGroup: Identifiable {
        let reel: Reel
        let places: [ReelPlace]
        var id: UUID { reel.id }
    }

    /// Finished reels that have at least one place, newest first (the store's order).
    private var groups: [PlaceGroup] {
        store.reels.compactMap { reel in
            guard !reel.status.isLive, reel.status != .failed, !reel.places.isEmpty else { return nil }
            return PlaceGroup(reel: reel, places: reel.places)
        }
    }
    private var allPlaces: [ReelPlace] { groups.flatMap(\.places) }
    private var total: Int { allPlaces.count }
    private var spread: [UUID: CLLocationCoordinate2D] { PlaceSpread.coordinates(for: allPlaces) }

    /// One map pin per place the backend could locate (no conditionals inside the map builder).
    private struct Pin: Identifiable {
        let reel: Reel
        let place: ReelPlace
        let number: Int?
        let coordinate: CLLocationCoordinate2D
        var id: UUID { place.id }
    }

    private var pins: [Pin] {
        let coordinates = spread
        return groups.flatMap { group in
            group.places.enumerated().compactMap { index, place -> Pin? in
                guard let coordinate = coordinates[place.id] else { return nil }
                return Pin(reel: group.reel, place: place, number: group.places.count > 1 ? index + 1 : nil,
                           coordinate: coordinate)
            }
        }
    }

    private func owner(of place: ReelPlace) -> Reel? { groups.first { $0.places.contains(place) }?.reel }
    private var selected: (reel: Reel, place: ReelPlace)? {
        let place = allPlaces.first { $0.id == selectedPlaceID } ?? allPlaces.first
        guard let place, let reel = owner(of: place) else { return nil }
        return (reel, place)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Map(position: $cameraPosition) {
                ForEach(pins) { pin in
                    Annotation(pin.place.name, coordinate: pin.coordinate) {
                        Button { select(pin.place) } label: { self.pin(pin.reel, place: pin.place, number: pin.number) }
                    }
                }
            }
            .ignoresSafeArea()

            panel
        }
    }

    // MARK: - Map

    private func pin(_ reel: Reel, place: ReelPlace, number: Int?) -> some View {
        let isSelected = selected?.place.id == place.id
        return ZStack(alignment: .topTrailing) {
            ReelCover(reel: reel).aspectRatio(contentMode: .fill)
                .frame(width: isSelected ? 46 : 36, height: isSelected ? 46 : 36)
                .clipShape(Circle())
                .overlay(Circle().stroke(isSelected ? Theme.accent : Theme.surface, lineWidth: 3))
                .shadow(radius: 6)
            if let number {
                Text("\(number)").font(.system(size: 10, weight: .bold)).foregroundStyle(.white)
                    .frame(width: 17, height: 17).background(Theme.accent, in: Circle())
                    .overlay(Circle().stroke(Theme.surface, lineWidth: 1.5))
                    .offset(x: 5, y: -5)
            }
        }
    }

    /// Zooms to one place; an approximate pin (area or city) gets a wider view than an exact one.
    private func select(_ place: ReelPlace) {
        withAnimation(Theme.Spring.snappy) { selectedPlaceID = place.id }
        guard let coordinate = spread[place.id] else { return }
        let span: Double = place.precision == "city" ? 0.25 : place.precision == "area" ? 0.06 : 0.012
        withAnimation(.easeInOut(duration: 0.6)) {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate, span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)))
        }
    }

    /// Frames every pin of one reel at once.
    private func fit(_ group: PlaceGroup) {
        let points = group.places.compactMap { spread[$0.id] }
        guard let first = points.first else { return }
        if let place = group.places.first { withAnimation(Theme.Spring.snappy) { selectedPlaceID = place.id } }
        var minLat = first.latitude, maxLat = first.latitude, minLon = first.longitude, maxLon = first.longitude
        for p in points {
            minLat = min(minLat, p.latitude); maxLat = max(maxLat, p.latitude)
            minLon = min(minLon, p.longitude); maxLon = max(maxLon, p.longitude)
        }
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: max((maxLat - minLat) * 1.6, 0.05),
                                    longitudeDelta: max((maxLon - minLon) * 1.6, 0.05))
        withAnimation(.easeInOut(duration: 0.6)) { cameraPosition = .region(MKCoordinateRegion(center: center, span: span)) }
    }

    // MARK: - Overview panel

    private var panel: some View {
        VStack(spacing: 10) {
            panelHeader

            if expanded {
                if groups.isEmpty {
                    VStack(spacing: 6) {
                        Image(systemName: "mappin.slash").font(.system(size: 24)).foregroundStyle(Theme.textSecondary)
                        Text("No places yet. Reels about somewhere real show up here.")
                            .font(Theme.Font.body(14)).foregroundStyle(Theme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 24).padding(.horizontal, 24)
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            // Reports how far the list is scrolled, so a downward swipe collapses only from the top.
                            GeometryReader { geo in
                                Color.clear.preference(key: ListOffsetKey.self,
                                                       value: geo.frame(in: .named("placesList")).minY)
                            }
                            .frame(height: 0)
                            ForEach(groups) { group in groupCard(group) }
                        }
                        .padding(.horizontal, 14)
                    }
                    .coordinateSpace(name: "placesList")
                    .onPreferenceChange(ListOffsetKey.self) { listAtTop = $0 >= -2 }
                    .frame(maxHeight: 270)
                    // Collapse only on a long, fast downward fling that started with the list at the very top.
                    // An ordinary scroll back to the top never qualifies; the handle always works for a plain drag.
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 30)
                            .onChanged { _ in if dragStartedAtTop == nil { dragStartedAtTop = listAtTop } }
                            .onEnded { value in
                                defer { dragStartedAtTop = nil }
                                guard dragStartedAtTop == true, listAtTop else { return }
                                if value.translation.height > 140 && value.predictedEndTranslation.height > 320 {
                                    setExpanded(false)
                                }
                            }
                    )

                    if let current = selected { actions(current.reel, current.place) }
                }
            }
        }
        .padding(.bottom, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .padding(8)
    }

    /// Handle, title and count. Drag it, or tap it, to collapse or expand the panel.
    private var panelHeader: some View {
        VStack(spacing: 10) {
            Capsule().fill(Theme.textSecondary.opacity(0.35)).frame(width: 40, height: 5).padding(.top, 10)
            HStack(alignment: .firstTextBaseline) {
                Text("Places").font(Theme.Font.display(28))
                Spacer()
                if total > 0 {
                    Text("\(total) place\(total == 1 ? "" : "s") · \(groups.count) reel\(groups.count == 1 ? "" : "s")")
                        .font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)
                }
                Image(systemName: expanded ? "chevron.down" : "chevron.up")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(Theme.textSecondary)
            }
            .padding(.horizontal, 20)
        }
        .contentShape(Rectangle())
        .onTapGesture { setExpanded(!expanded) }
        .gesture(
            DragGesture(minimumDistance: 10).onEnded { value in
                if value.translation.height > 25 { setExpanded(false) }
                else if value.translation.height < -25 { setExpanded(true) }
            }
        )
    }

    private func setExpanded(_ value: Bool) {
        withAnimation(Theme.Spring.snappy) { expanded = value }
    }

    /// One reel and all of its places. Tap the header to fold the group; the scope button frames its pins.
    private func groupCard(_ group: PlaceGroup) -> some View {
        let folded = collapsedGroups.contains(group.id)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button { toggleGroup(group.id) } label: {
                    HStack(spacing: 10) {
                        ReelCover(reel: group.reel).aspectRatio(contentMode: .fill)
                            .frame(width: 34, height: 34)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(group.reel.title ?? "Reel").font(Theme.Font.body(13, weight: .semibold))
                                .foregroundStyle(Theme.aiFg).lineLimit(1)
                            Text("\(group.places.count) place\(group.places.count == 1 ? "" : "s")")
                                .font(Theme.Font.body(11)).foregroundStyle(Theme.textSecondary)
                        }
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.down").font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textSecondary)
                            .rotationEffect(.degrees(folded ? -90 : 0))
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if group.places.count > 1 {
                    Button { fit(group) } label: {
                        Image(systemName: "scope").font(.system(size: 13, weight: .semibold))
                            .frame(width: 32, height: 32).background(Theme.surface, in: Circle())
                    }
                    .buttonStyle(.plain).foregroundStyle(Theme.text)
                    .accessibilityLabel("Show all places from this reel on the map")
                }
            }
            .padding(.horizontal, 4)

            if !folded {
                ForEach(Array(group.places.enumerated()), id: \.element.id) { index, place in
                    row(place, number: group.places.count > 1 ? index + 1 : nil)
                }
            }
        }
        .padding(8)
        .background(Theme.surface2.opacity(0.55), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func toggleGroup(_ id: UUID) {
        withAnimation(Theme.Spring.snappy) {
            if collapsedGroups.contains(id) { collapsedGroups.remove(id) } else { collapsedGroups.insert(id) }
        }
    }

    private func row(_ place: ReelPlace, number: Int?) -> some View {
        let isSelected = selected?.place.id == place.id
        return Button { select(place) } label: {
            HStack(spacing: 10) {
                if let number {
                    Text("\(number)").font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(Theme.accent, in: Circle())
                } else {
                    Image(systemName: "mappin.circle.fill").font(.system(size: 20)).foregroundStyle(Theme.placeFg)
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(place.name).font(Theme.Font.body(15, weight: .semibold)).lineLimit(1)
                        if place.isApproximate {
                            Text("Approx.").font(Theme.Font.body(9, weight: .bold))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.surface, in: Capsule())
                                .foregroundStyle(Theme.textSecondary)
                        }
                    }
                    if !place.subtitle.isEmpty {
                        Text(place.subtitle).font(Theme.Font.body(12)).foregroundStyle(Theme.textSecondary).lineLimit(1)
                    }
                }
                Spacer(minLength: 4)
                if place.coordinate == nil {
                    // Has a place name but the map could not locate it.
                    Image(systemName: "mappin.slash").font(.system(size: 13)).foregroundStyle(Theme.textSecondary)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Theme.placeBg : Theme.surface,
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.text)
    }

    private func actions(_ reel: Reel, _ place: ReelPlace) -> some View {
        HStack(spacing: 10) {
            if let url = URL(string: place.mapURL), !place.mapURL.isEmpty {
                Link(destination: url) {
                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                        .font(Theme.Font.body(15, weight: .semibold))
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Theme.accent, in: Capsule()).foregroundStyle(.white)
                }
            }
            NavigationLink {
                ReelDetailView(reelID: reel.id)
            } label: {
                Text("Open reel").font(Theme.Font.body(15, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .background(Theme.surface2, in: Capsule()).foregroundStyle(Theme.text)
            }
        }
        .padding(.horizontal, 14).padding(.top, 2)
    }
}

private struct ListOffsetKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
