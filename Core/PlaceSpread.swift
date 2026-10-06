import CoreLocation

/// Several places can share one pin location (a list reel whose spots are only known to city level).
/// This fans them out in a small ring around the shared point so each one stays visible and tappable.
enum PlaceSpread {
    static func coordinates(for places: [ReelPlace]) -> [UUID: CLLocationCoordinate2D] {
        var buckets: [String: [ReelPlace]] = [:]
        for place in places {
            guard let c = place.coordinate else { continue }
            buckets[String(format: "%.3f,%.3f", c.latitude, c.longitude), default: []].append(place)
        }
        var result: [UUID: CLLocationCoordinate2D] = [:]
        for group in buckets.values {
            for (index, place) in group.enumerated() {
                guard let c = place.coordinate else { continue }
                if group.count == 1 {
                    result[place.id] = CLLocationCoordinate2D(latitude: c.latitude, longitude: c.longitude)
                } else {
                    let angle = 2 * Double.pi * Double(index) / Double(group.count)
                    let radius = 0.012  // about 1.3 km
                    result[place.id] = CLLocationCoordinate2D(latitude: c.latitude + radius * sin(angle),
                                                              longitude: c.longitude + radius * cos(angle))
                }
            }
        }
        return result
    }
}
