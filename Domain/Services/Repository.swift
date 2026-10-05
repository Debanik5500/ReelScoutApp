import Foundation

protocol ReelScoutRepository {
    func getHome() async throws -> ReelScoutResponse
    func getReel(id: String) async throws -> Reel
    func getGroup(id: String) async throws -> ReelGroup
    func getSource(id: String) async throws -> Source
    func analyze(input: AnalyzeInput) async throws -> AnalysisJob
    func saveReel(_ reel: Reel) async throws
    func unsaveReel(id: String) async throws
    func getSavedReels() async throws -> [Reel]
}

struct AnalyzeInput: Codable {
    let url: String?
    let mediaData: Data?
    let mediaType: MediaType?
    let sourceType: SourceType?
    
    enum MediaType: String, Codable {
        case image
        case video
    }
}

struct AnalysisJob: Codable {
    let jobId: String
    let status: JobStatus
    let estimatedDuration: Int?
    let reelId: String?
    
    enum JobStatus: String, Codable {
        case queued
        case processing
        case completed
        case failed
    }
}

final class MockReelScoutRepository: ReelScoutRepository {
    private let mockResponse: ReelScoutResponse

    init() {
        self.mockResponse = Self.loadMockResponse()
    }

    private static func loadMockResponse() -> ReelScoutResponse {
        guard let url = Bundle.main.url(forResource: "mock_home", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return ReelScoutResponse(
                schemaVersion: "1.0",
                generatedAt: Date(),
                summary: ResponseSummary(totalReels: 0, totalGroups: 0, recentCount: 0),
                sources: [],
                groups: [],
                reels: [],
                homeSections: []
            )
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode(ReelScoutResponse.self, from: data)) ?? ReelScoutResponse(
            schemaVersion: "1.0",
            generatedAt: Date(),
            summary: ResponseSummary(totalReels: 0, totalGroups: 0, recentCount: 0),
            sources: [],
            groups: [],
            reels: [],
            homeSections: []
        )
    }

    func getHome() async throws -> ReelScoutResponse {
        try await Task.sleep(nanoseconds: 500_000_000)
        return mockResponse
    }
    
    func getReel(id: String) async throws -> Reel {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let reel = mockResponse.reels.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return reel
    }
    
    func getGroup(id: String) async throws -> ReelGroup {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let group = mockResponse.groups.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return group
    }
    
    func getSource(id: String) async throws -> Source {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let source = mockResponse.sources.first(where: { $0.id == id }) else {
            throw RepositoryError.notFound
        }
        return source
    }
    
    func analyze(input: AnalyzeInput) async throws -> AnalysisJob {
        try await Task.sleep(nanoseconds: 1_000_000_000)
        return AnalysisJob(
            jobId: UUID().uuidString,
            status: .queued,
            estimatedDuration: 30,
            reelId: UUID().uuidString
        )
    }
    
    func saveReel(_ reel: Reel) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    func unsaveReel(id: String) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }
    
    func getSavedReels() async throws -> [Reel] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return mockResponse.reels.filter { $0.id == "reel_001" || $0.id == "reel_003" }
    }
}

enum RepositoryError: LocalizedError {
    case notFound
    case networkError
    case decodingError
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Item not found"
        case .networkError: return "Network error occurred"
        case .decodingError: return "Failed to decode response"
        case .unauthorized: return "Unauthorized access"
        }
    }
}