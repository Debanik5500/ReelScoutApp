import Foundation

struct Action: Codable, Identifiable, Hashable {
    let id: String
    let type: ActionType
    let label: String
    let icon: String?
    let url: String?
    let payload: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id, type, label, icon, url, payload
    }
}

enum ActionType: String, Codable {
    case directions
    case website
    case menu
    case reservation
    case github
    case documentation
    case product
    case shopping
    case map
    case save
    case addToTrip = "add_to_trip"
    case external
    case share
    case call
    case email
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = ActionType(rawValue: raw) ?? .unknown
    }
    
    var systemIcon: String {
        switch self {
        case .directions: return "location.fill"
        case .website: return "globe"
        case .menu: return "menucard"
        case .reservation: return "calendar.badge.plus"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .documentation: return "doc.text"
        case .product: return "bag"
        case .shopping: return "cart"
        case .map: return "map"
        case .save: return "bookmark"
        case .addToTrip: return "suitcase"
        case .external: return "arrow.up.right.square"
        case .share: return "square.and.arrow.up"
        case .call: return "phone"
        case .email: return "envelope"
        case .unknown: return "questionmark"
        }
    }
}