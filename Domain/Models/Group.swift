import Foundation

struct ReelGroup: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let description: String?
    let type: GroupType
    let icon: Icon
    let coverImageUrl: String?
    let reelIds: [String]
    let count: Int
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, type, icon
        case coverImageUrl = "cover_image_url"
        case reelIds = "reel_ids"
        case count
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

enum GroupType: String, Codable {
    case semantic
    case location
    case topic
    case source
    case collection
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = GroupType(rawValue: raw) ?? .unknown
    }
}