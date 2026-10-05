import Foundation

struct Source: Codable, Identifiable, Hashable {
    let id: String
    let type: SourceType
    let name: String
    let icon: Icon
    let count: Int
    let reelIds: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, icon, count
        case reelIds = "reel_ids"
    }
}

enum SourceType: String, Codable, CaseIterable {
    case instagram
    case tiktok
    case youtube
    case whatsapp
    case gallery
    case safari
    case upload
    case other
    case unknown
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = SourceType(rawValue: raw) ?? .unknown
    }
    
    var displayName: String {
        switch self {
        case .instagram: return "Instagram"
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        case .whatsapp: return "WhatsApp"
        case .gallery: return "Gallery"
        case .safari: return "Safari"
        case .upload: return "Upload"
        case .other: return "Other"
        case .unknown: return "Unknown"
        }
    }
    
    var systemIcon: String {
        switch self {
        case .instagram: return "camera"
        case .tiktok: return "music.note"
        case .youtube: return "play.rectangle"
        case .whatsapp: return "message"
        case .gallery: return "photo.on.rectangle"
        case .safari: return "safari"
        case .upload: return "square.and.arrow.up"
        case .other: return "ellipsis"
        case .unknown: return "questionmark"
        }
    }
}