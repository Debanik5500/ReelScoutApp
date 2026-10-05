import Foundation

struct ProcessingState: Equatable {
    let stage: ProcessingStage
    let progress: Double
    let message: String
    let reelPreview: ReelPreview?
}

enum ProcessingStage: String, CaseIterable {
    case watching
    case listening
    case identifying
    case lookingUp = "looking_up"
    case enriching
    case organizing
    case completed
    case failed
    
    var displayName: String {
        switch self {
        case .watching: return "Watching"
        case .listening: return "Listening"
        case .identifying: return "Identifying"
        case .lookingUp: return "Looking it up"
        case .enriching: return "Enriching"
        case .organizing: return "Organizing"
        case .completed: return "Complete"
        case .failed: return "Failed"
        }
    }
    
    var icon: String {
        switch self {
        case .watching: return "eye"
        case .listening: return "waveform"
        case .identifying: return "magnifyingglass"
        case .lookingUp: return "globe"
        case .enriching: return "sparkles"
        case .organizing: return "folder"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
    
    var isComplete: Bool {
        self == .completed || self == .failed
    }
}

struct ReelPreview: Equatable {
    let thumbnailUrl: String?
    let videoUrl: String?
    let title: String?
    let sourceName: String?
}