import Foundation

struct SharePayload: Codable {
    let url: String?
    let text: String?
    let imageData: Data?
    let videoURL: String?
    let sourceApp: String?
    let detectedSource: String?

    var hasContent: Bool {
        url != nil || imageData != nil || videoURL != nil || (text?.isEmpty == false)
    }
}
