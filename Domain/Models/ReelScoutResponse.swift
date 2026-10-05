import Foundation

struct ReelScoutResponse: Codable {
    let schemaVersion: String
    let generatedAt: Date
    let summary: ResponseSummary
    let sources: [Source]
    let groups: [ReelGroup]
    let reels: [Reel]
    let homeSections: [HomeSection]
    
    enum CodingKeys: String, CodingKey {
        case schemaVersion = "schema_version"
        case generatedAt = "generated_at"
        case summary
        case sources
        case groups
        case reels
        case homeSections = "home_sections"
    }
}

struct ResponseSummary: Codable {
    let totalReels: Int
    let totalGroups: Int
    let recentCount: Int
    
    enum CodingKeys: String, CodingKey {
        case totalReels = "total_reels"
        case totalGroups = "total_groups"
        case recentCount = "recent_count"
    }
}