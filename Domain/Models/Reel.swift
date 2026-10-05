import Foundation

struct Reel: Codable, Identifiable, Hashable {
    let id: String
    let source: ReelSource
    let media: Media
    let content: Content
    let entity: Entity?
    let groups: [String]
    let attributes: [Attribute]
    let insights: [Insight]
    let actions: [Action]
    let metadata: Metadata
    
    var groupNames: [String] {
        groups
    }
}

struct ReelSource: Codable, Hashable {
    let type: SourceType
    let url: String?
    let creator: Creator?
}

struct Creator: Codable, Hashable {
    let name: String?
    let handle: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case name, handle
        case avatarUrl = "avatar_url"
    }
}

struct Media: Codable, Hashable {
    let thumbnailUrl: String?
    let videoUrl: String?
    let durationSeconds: Int?
    
    enum CodingKeys: String, CodingKey {
        case thumbnailUrl = "thumbnail_url"
        case videoUrl = "video_url"
        case durationSeconds = "duration_seconds"
    }
}

struct Content: Codable, Hashable {
    let type: ContentType
    let category: String?
    let title: String?
    let summary: String?
    let description: String?
    let tags: [String]
}

enum ContentType: String, Codable {
    case place
    case software
    case product
    case information
    case event
    case recipe
    case travel
    case shopping
    case entertainment
    case education
    case health
    case finance
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = ContentType(rawValue: raw) ?? .unknown
    }
}

struct Entity: Codable, Hashable {
    let type: EntityType
    let name: String
    let verified: Bool?
    let location: Location?
    let website: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case type, name, verified, location, website, phone
    }
}

enum EntityType: String, Codable {
    case restaurant
    case hotel
    case attraction
    case shop
    case developerTool = "developer_tool"
    case library
    case framework
    case product
    case brand
    case person
    case organization
    case event
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = EntityType(rawValue: raw) ?? .unknown
    }
}

struct Location: Codable, Hashable {
    let name: String?
    let city: String?
    let country: String?
    let latitude: Double?
    let longitude: Double?
    let address: String?
    let neighborhood: String?
    
    var coordinate: (lat: Double, lon: Double)? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return (lat, lon)
    }
    
    var displayString: String {
        var parts: [String] = []
        if let name = name { parts.append(name) }
        if let neighborhood = neighborhood { parts.append(neighborhood) }
        if let city = city { parts.append(city) }
        if let country = country { parts.append(country) }
        return parts.joined(separator: ", ")
    }
}