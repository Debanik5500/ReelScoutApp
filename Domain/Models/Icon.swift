import Foundation

struct Icon: Codable, Hashable {
    let type: IconType
    let name: String
    
    enum IconType: String, Codable {
        case sfSymbol = "sf_symbol"
        case url
        case system
        case unknown
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let raw = try container.decode(String.self)
            self = IconType(rawValue: raw) ?? .unknown
        }
    }
    
    var systemName: String {
        switch type {
        case .sfSymbol, .system:
            return name
        case .url:
            return "photo"
        case .unknown:
            return "questionmark"
        }
    }
}