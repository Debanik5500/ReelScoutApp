import Foundation

struct Insight: Codable, Identifiable, Hashable {
    let id: String
    let timestamp: Double
    let imageUrl: String?
    let thumbnailUrl: String?
    let reason: String
    let type: InsightType
    
    enum CodingKeys: String, CodingKey {
        case id, timestamp
        case imageUrl = "image_url"
        case thumbnailUrl = "thumbnail_url"
        case reason, type
    }
}

enum InsightType: String, Codable {
    case place
    case business
    case restaurant
    case cafe
    case bar
    case event
    case activity
    case shop
    case landmark
    case transit
    case entityEvidence = "entity_evidence"
    case menuEvidence = "menu_evidence"
    case locationEvidence = "location_evidence"
    case productEvidence = "product_evidence"
    case textEvidence = "text_evidence"
    case visualEvidence = "visual_evidence"
    case audioEvidence = "audio_evidence"
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = InsightType(rawValue: raw) ?? .unknown
    }

    var iconName: String {
        switch self {
        case .place: return "mappin.and.ellipse"
        case .business: return "building.2"
        case .restaurant: return "fork.knife"
        case .cafe: return "cup.and.saucer"
        case .bar: return "wineglass"
        case .event: return "calendar"
        case .activity: return "figure.walk"
        case .shop: return "bag"
        case .landmark: return "building.columns"
        case .transit: return "bus"
        case .entityEvidence: return "sparkles"
        case .menuEvidence: return "text.book.closed"
        case .locationEvidence: return "location"
        case .productEvidence: return "cube.box"
        case .textEvidence: return "doc.text"
        case .visualEvidence: return "photo"
        case .audioEvidence: return "waveform"
        case .unknown: return "questionmark.circle"
        }
    }

    var displayName: String {
        switch self {
        case .place: return "Place"
        case .business: return "Business"
        case .restaurant: return "Restaurant"
        case .cafe: return "Café"
        case .bar: return "Bar"
        case .event: return "Event"
        case .activity: return "Activity"
        case .shop: return "Shop"
        case .landmark: return "Landmark"
        case .transit: return "Transit"
        case .entityEvidence: return "Entity"
        case .menuEvidence: return "Menu"
        case .locationEvidence: return "Location"
        case .productEvidence: return "Product"
        case .textEvidence: return "Text"
        case .visualEvidence: return "Visual"
        case .audioEvidence: return "Audio"
        case .unknown: return "Unknown"
        }
    }
}