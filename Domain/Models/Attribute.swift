import Foundation

struct Attribute: Codable, Identifiable, Hashable {
    let id = UUID()
    let key: String
    let label: String
    let value: String
    let icon: String?
    let type: AttributeType?
    
    enum CodingKeys: String, CodingKey {
        case key, label, value, icon, type
    }
}

enum AttributeType: String, Codable {
    case location
    case time
    case category
    case price
    case rating
    case url
    case phone
    case hours
    case website
    case address
    case distance
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = AttributeType(rawValue: raw) ?? .unknown
    }

    var icon: String {
        switch self {
        case .location: return "mappin.and.ellipse"
        case .time: return "clock"
        case .category: return "tag"
        case .price: return "dollarsign.circle"
        case .rating: return "star"
        case .url: return "link"
        case .phone: return "phone"
        case .hours: return "clock"
        case .website: return "globe"
        case .address: return "location"
        case .distance: return "location.north"
        case .unknown: return "questionmark.circle"
        }
    }
}