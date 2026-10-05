import SwiftUI

extension SourceType {
    var iconName: String { systemIcon }

    var colorHex: String {
        switch self {
        case .instagram: return "E4405F"
        case .tiktok: return "010101"
        case .youtube: return "FF0000"
        case .whatsapp: return "25D366"
        case .gallery: return "AF52DE"
        case .safari: return "006CFF"
        case .upload: return "34C759"
        case .other, .unknown: return "9E9E9E"
        }
    }
}

extension ReelSource {
    var iconName: String { type.iconName }
    var colorHex: String { type.colorHex }
    var displayName: String { type.displayName }
}

extension EntityType {
    var iconName: String {
        switch self {
        case .restaurant: return "fork.knife"
        case .hotel: return "bed.double.fill"
        case .attraction: return "camera.fill"
        case .shop: return "bag.fill"
        case .developerTool: return "wrench.and.screwdriver.fill"
        case .library: return "books.vertical.fill"
        case .framework: return "cube"
        case .product: return "shippingbox.fill"
        case .brand: return "star.fill"
        case .person: return "person.fill"
        case .organization: return "building.2.fill"
        case .event: return "calendar"
        case .unknown: return "questionmark"
        }
    }
}

extension DisplayStyle {
    var iconName: String {
        switch self {
        case .grid: return "square.grid.2x2.fill"
        case .list: return "list.bullet"
        case .carousel: return "rectangle.stack.fill"
        case .featured: return "star.fill"
        case .compact: return "rectangle.compress.vertical"
        case .unknown: return "questionmark"
        }
    }
}

extension GroupType {
    var displayName: String {
        switch self {
        case .semantic: return "Smart Collection"
        case .location: return "Location"
        case .topic: return "Topic"
        case .source: return "Source"
        case .collection: return "Collection"
        case .unknown: return "Unknown"
        }
    }
}

extension Content {
    var displayText: String {
        if let title, !title.isEmpty { return title }
        if let summary, !summary.isEmpty { return summary }
        if let description, !description.isEmpty { return description }
        return "Untitled reel"
    }
}
