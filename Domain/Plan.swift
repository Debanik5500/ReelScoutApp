import Foundation

/// One subscription plan, read from the server's plans config (so prices and limits change without an app update).
struct Plan: Identifiable, Codable, Hashable {
    let id: String
    var name: String
    var monthlyReels: Int
    var priceUSDMonth: Double
    var tagline: String
    var features: [String]
    /// false shows the plan as "Coming soon" (no payments yet).
    var available: Bool

    private enum CodingKeys: String, CodingKey {
        case id, name, tagline, features, available
        case monthlyReels = "monthly_reels"
        case priceUSDMonth = "price_usd_month"
    }

    var isFree: Bool { priceUSDMonth == 0 }
}

struct PlansConfig: Codable {
    var freePlan: String
    var plans: [Plan]

    private enum CodingKeys: String, CodingKey {
        case plans
        case freePlan = "free_plan"
    }

    /// Shown until the server answers (and when it never does), so the page is never empty.
    static let fallback = PlansConfig(freePlan: "free", plans: [
        Plan(id: "free", name: "Free", monthlyReels: 5, priceUSDMonth: 0,
             tagline: "Try Kept with 5 reels every month",
             features: ["5 reels or posts a month", "Key moments, places and links", "Everything stays on your phone"],
             available: true)
    ])
}

/// How many reels this device has used this month.
struct Quota: Codable, Hashable {
    var plan: String
    var planName: String
    var limit: Int?        // nil: not metered
    var used: Int
    var remaining: Int?
    var resetsAt: Date?

    private enum CodingKeys: String, CodingKey {
        case plan, limit, used, remaining
        case planName = "plan_name"
        case resetsAt = "resets_at"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plan = (try? c.decode(String.self, forKey: .plan)) ?? "free"
        planName = (try? c.decode(String.self, forKey: .planName)) ?? "Free"
        limit = try? c.decodeIfPresent(Int.self, forKey: .limit)
        used = (try? c.decode(Int.self, forKey: .used)) ?? 0
        remaining = try? c.decodeIfPresent(Int.self, forKey: .remaining)
        if let raw = try? c.decode(String.self, forKey: .resetsAt) {
            resetsAt = ISO8601DateFormatter().date(from: raw)
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(plan, forKey: .plan); try c.encode(planName, forKey: .planName)
        try c.encodeIfPresent(limit, forKey: .limit); try c.encode(used, forKey: .used)
        try c.encodeIfPresent(remaining, forKey: .remaining)
        if let resetsAt { try c.encode(ISO8601DateFormatter().string(from: resetsAt), forKey: .resetsAt) }
    }

    var isMetered: Bool { limit != nil }
    var isOut: Bool { (remaining ?? 1) <= 0 }
}
