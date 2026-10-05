import Foundation

struct Metadata: Codable, Hashable {
    let createdAt: Date
    let updatedAt: Date
    let processedAt: Date?
    let sourceId: String?
    let confidence: Double?
    let version: String?
    
    enum CodingKeys: String, CodingKey {
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case processedAt = "processed_at"
        case sourceId = "source_id"
        case confidence, version
    }
}

struct HomeSection: Codable, Identifiable, Hashable {
    let id: String
    let type: HomeSectionType
    let title: String
    let groupId: String?
    let reelIds: [String]
    let displayStyle: DisplayStyle?
    let limit: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, type, title
        case groupId = "group_id"
        case reelIds = "reel_ids"
        case displayStyle = "display_style"
        case limit
    }
}

enum HomeSectionType: String, Codable {
    case recent
    case group
    case source
    case saved
    case recommended
    case trending
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = HomeSectionType(rawValue: raw) ?? .unknown
    }
}

enum DisplayStyle: String, Codable {
    case grid
    case list
    case carousel
    case featured
    case compact
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = DisplayStyle(rawValue: raw) ?? .unknown
    }
}