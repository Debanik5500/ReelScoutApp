import Foundation

/// Seeds the app with the same sample content used in the Kept design, so the
/// UI matches the mockups out of the box. Replace with a real API client later.
struct MockReelService: ReelService {
    func seedBoards() -> [Board] {
        [tokyo, moveMore, baking]
    }

    let tokyo = Board(name: "Tokyo, October")
    let moveMore = Board(name: "Move more")
    let baking = Board(name: "Weekend baking")

    func seedReels() -> [Reel] {
        [
            Reel(sourceURL: "https://instagram.com/reel/1", author: "@alley.notes",
                 coverImageName: "cover_ramen", duration: "0:42", status: .ready,
                 title: "Hidden ramen counters in Shinjuku",
                 gist: "A late-night walk through Shinjuku's ramen counters, ending at an eight-seat bar in Golden Gai most people walk right past.",
                 keyMoments: [
                    .init(timestamp: "0:03", label: "The alley entrance", note: "Look for the red lantern past the second bar.", imageName: "cover_alley"),
                    .init(timestamp: "0:11", label: "Ticket machine first", note: "Shio ramen is the top-left button.", imageName: "cover_ramen"),
                    .init(timestamp: "0:19", label: "Clear shio broth", note: "Clear chicken shio, finished with yuzu.", imageName: "cover_ramen"),
                    .init(timestamp: "0:28", label: "Only eight seats", note: "Solo diners get seated first.", imageName: "cover_alley"),
                    .init(timestamp: "0:37", label: "Lane four, red lantern", note: "Golden Gai, lane four.", imageName: "cover_alley"),
                 ],
                 points: [
                    .init(text: "Go after 9pm. The queue thins and counters stay open until 2am."),
                    .init(text: "Cash only. Shio ramen is the top-left button on the ticket machine."),
                    .init(text: "Eight seats, so solo diners get in fastest."),
                 ],
                 place: .init(name: "Golden Gai, Kabukicho", subtitle: "From the link in the reel", mapURL: "https://maps.app.goo.gl/golden-gai"),
                 boardID: tokyo.id, category: "Food", liked: true),

            Reel(sourceURL: "https://instagram.com/reel/2", author: "@slowtokyo",
                 coverImageName: "cover_sunrise", duration: "0:31", status: .ready,
                 title: "Yanaka at sunrise",
                 gist: "An old-town walk before the shops open, starting at the cemetery gate.",
                 points: [.init(text: "Best light is 30 minutes after sunrise.")],
                 place: .init(name: "Yanaka", subtitle: "Taito, Tokyo", mapURL: "https://maps.app.goo.gl/yanaka"),
                 boardID: tokyo.id, category: "Travel"),

            Reel(sourceURL: "https://instagram.com/reel/3", author: "@movedaily",
                 coverImageName: "cover_workout", duration: "1:04", status: .ready,
                 title: "20-minute routine, one kettlebell",
                 gist: "Five moves, 40 seconds each, two rounds. Rest 20 between.",
                 points: [.init(text: "Swap the swing for a deadlift on week one.")],
                 boardID: moveMore.id, category: "Fitness"),

            Reel(sourceURL: "https://instagram.com/reel/4", author: "@crumbshot",
                 coverImageName: "cover_bread", duration: "0:58", status: .ready,
                 title: "Sourdough at 75% hydration",
                 gist: "Easier shaping. Bake at 240°C covered, then 20 minutes open.",
                 boardID: baking.id, category: "Food"),

            Reel(sourceURL: "https://instagram.com/reel/5", author: "@slowtokyo",
                 coverImageName: "cover_coffee", duration: "0:50", status: .ready,
                 title: "Jazz kissaten crawl in Jimbocho",
                 gist: "Quiet rooms before noon, vinyl and siphon coffee.",
                 place: .init(name: "Jimbocho kissaten", subtitle: "Chiyoda, Tokyo", mapURL: "https://maps.app.goo.gl/jimbocho"),
                 boardID: tokyo.id, category: "Travel"),

            Reel(sourceURL: "https://instagram.com/reel/6", author: "@smallrooms",
                 coverImageName: "cover_desk", duration: "0:36", status: .ready,
                 title: "A desk that keeps you focused",
                 gist: "One lamp, one plant, nothing on the left side of the keyboard.",
                 boardID: moveMore.id, category: "Home"),

            Reel(sourceURL: "https://instagram.com/reel/7", author: "@alley.notes",
                 coverImageName: "cover_alley", duration: "0:40", status: .ready,
                 title: "Golden Gai after dark",
                 gist: "The lanes light up at dusk; come early to find a seat.",
                 place: .init(name: "Kabukicho lanes", subtitle: "Shinjuku, Tokyo", mapURL: "https://maps.app.goo.gl/kabukicho"),
                 boardID: tokyo.id, category: "Travel"),

            Reel(sourceURL: "https://instagram.com/reel/8", author: "@tokyobites",
                 coverImageName: "cover_market", duration: "0:33", status: .ready,
                 title: "Tsukiji: eat it standing up",
                 gist: "Arrive before 9am for the tamagoyaki stall.",
                 place: .init(name: "Tsukiji outer market", subtitle: "Chuo, Tokyo", mapURL: "https://maps.app.goo.gl/tsukiji"),
                 boardID: tokyo.id, category: "Food"),

            // Two reels mid-processing, so the Library's live-status cards show immediately.
            Reel(sourceURL: "https://instagram.com/reel/9", author: "@movedaily",
                 coverImageName: "cover_workout", duration: "0:47", status: .watching, progress: 0.3,
                 boardID: moveMore.id, category: "Fitness"),

            Reel(sourceURL: "https://instagram.com/reel/10", author: "@tokyobites",
                 coverImageName: "cover_market", duration: "0:39", status: .downloading, progress: 0.6,
                 boardID: tokyo.id, category: "Food"),
        ]
    }

    func finalize(_ reel: inout Reel) {
        reel.title = "Tsukiji breakfast in 5 bites"
        reel.gist = "A five-stop standing breakfast through the outer market, arriving before the day crowd."
        reel.keyMoments = [
            .init(timestamp: "0:04", label: "Tamagoyaki on a stick", note: "Arrive before 9am.", imageName: "cover_market")
        ]
        reel.points = [.init(text: "Cash only, small bills.")]
        reel.place = .init(name: "Tsukiji outer market", subtitle: "Chuo, Tokyo", mapURL: "https://maps.app.goo.gl/tsukiji")
        reel.boardID = tokyo.id
        reel.category = "Food"
    }
}
