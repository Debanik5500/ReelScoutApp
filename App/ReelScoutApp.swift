import SwiftUI
import Combine

extension DesignSystem.ThemeColor {
    static let accent = DesignSystem.Palette.lime
}

struct SaveFlight {
    let from: CGPoint
    let start: Date
}

@main
struct ReelScoutApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environment(\.theme, Theme())
                .onAppear {
                    appState.loadHome()
                    appState.checkForSharedPayload()
                }
                .onOpenURL { url in
                    appState.handleIncomingURL(url)
                }
        }
    }
}

@MainActor
class AppState: ObservableObject {
    @Published var repository: ReelScoutRepository = MockReelScoutRepository()
    @Published var currentResponse: ReelScoutResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false

    @Published var processingState: ProcessingState?
    @Published var showProcessing = false

    @Published var selectedTab: Int = 0
    @Published var selectedReel: Reel?
    @Published var showDiscovery = false

    @Published var savedReelIds: Set<String> = []

    @Published var selectedGroup: ReelGroup?
    @Published var showGroupDetail = false
    @Published var selectedSource: Source?
    @Published var showSourceDetail = false

    /// Progressive discovery reveal: 0 = image, 1 = entity, 2 = insight, 3 = everything.
    @Published var revealStage: Int = 0

    // MARK: - Save flight (bookmark flies from the save control to the Saved tab)
    @Published var saveFlight: SaveFlight?
    @Published var saveFlightProgress: CGFloat = 0
    @Published var savedTabCenter: CGPoint?
    @Published var savedTabPulse: Int = 0

    func flySaveToSavedTab(from point: CGPoint) {
        guard let destination = savedTabCenter else {
            savedTabPulse += 1
            Haptics.tap()
            return
        }
        saveFlight = SaveFlight(from: point, start: Date())
        saveFlightProgress = 0
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            saveFlightProgress = 0.001
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.86).delay(0.1)) {
            saveFlightProgress = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.68) { [weak self] in
            guard let self else { return }
            self.saveFlight = nil
            self.saveFlightProgress = 0
            self.savedTabPulse += 1
            Haptics.cardSnap()
        }
    }

    func clearSaveFlight() {
        saveFlight = nil
    }

    var savedReels: [Reel] {
        (currentResponse?.reels ?? []).filter { savedReelIds.contains($0.id) }
    }

    func reels(in group: ReelGroup) -> [Reel] {
        (currentResponse?.reels ?? []).filter { group.reelIds.contains($0.id) }
    }

    func reels(in source: Source) -> [Reel] {
        (currentResponse?.reels ?? []).filter { source.reelIds.contains($0.id) }
    }

    func groupNames(for reel: Reel) -> [String] {
        (currentResponse?.groups ?? [])
            .filter { !Set($0.reelIds).isDisjoint(with: reel.groups) }
            .map { $0.name }
    }

    func relatedReels(for reel: Reel) -> [Reel] {
        let groupIds = Set(reel.groups)
        return (currentResponse?.reels ?? []).filter { other in
            guard other.id != reel.id else { return false }
            if !Set(other.groups).isDisjoint(with: groupIds) { return true }
            return other.source.type == reel.source.type
        }
        .prefix(3)
        .map { $0 }
    }

    func selectGroup(_ group: ReelGroup) {
        revealStage = 0
        selectedGroup = group
        showGroupDetail = true
    }

    func selectSource(_ source: Source) {
        revealStage = 0
        selectedSource = source
        showSourceDetail = true
    }

    func selectTab(_ index: Int) {
        guard index != selectedTab else { return }
        selectedTab = index
    }

    func loadHome() {
        isLoading = true
        Task {
            do {
                let response = try await repository.getHome()
                self.currentResponse = response
                self.errorMessage = nil
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.showError = true
                self.isLoading = false
            }
        }
    }

    func selectReel(_ reel: Reel) {
        revealStage = 0
        selectedReel = reel
        showDiscovery = true
    }

    func startProcessing(with payload: SharePayload) {
        let preview = ReelPreview(
            thumbnailUrl: nil,
            videoUrl: nil,
            title: payload.url ?? payload.text,
            sourceName: payload.sourceApp
        )
        processingState = ProcessingState(
            stage: .watching,
            progress: 0.1,
            message: "Watching your Reel...",
            reelPreview: preview
        )
        showProcessing = true
        simulateProcessing()
    }

    private func simulateProcessing() {
        let stages: [(ProcessingStage, Double, String)] = [
            (.watching, 0.15, "Watching your Reel..."),
            (.listening, 0.30, "Listening to audio..."),
            (.identifying, 0.50, "Identifying content..."),
            (.lookingUp, 0.70, "Looking it up..."),
            (.enriching, 0.85, "Finding useful details..."),
            (.organizing, 0.95, "Building your discovery..."),
            (.completed, 1.0, "Found something for you!")
        ]

        for (index, (stage, progress, message)) in stages.enumerated() {
            Task { @MainActor in
                let nanos = UInt64(index) * 1_200_000_000
                try? await Task.sleep(nanoseconds: nanos)
                self.processingState = ProcessingState(
                    stage: stage,
                    progress: progress,
                    message: message,
                    reelPreview: self.processingState?.reelPreview
                )
            }
        }
    }

    func completeProcessing() {
        showProcessing = false
        if let response = currentResponse, let firstReel = response.reels.first {
            selectedReel = firstReel
            showDiscovery = true
        }
        processingState = nil
    }

    func retryProcessing() {
        processingState = nil
        showProcessing = false
    }

    func handleIncomingURL(_ url: URL) {
        guard url.scheme == "reelscout" else { return }

        if url.host == "processing" {
            if processingState == nil {
                processingState = ProcessingState(
                    stage: .watching,
                    progress: 0.1,
                    message: "Watching your Reel...",
                    reelPreview: nil
                )
            }
            showProcessing = true
        } else if url.host == "reel", let reelId = url.pathComponents.last {
            Task {
                if let reel = try? await repository.getReel(id: reelId) {
                    selectedReel = reel
                    showDiscovery = true
                }
            }
        }
    }

    func checkForSharedPayload() {
        Task.detached {
            guard let defaults = UserDefaults(suiteName: "group.com.reelscout.app"),
                  let data = defaults.data(forKey: "pendingSharePayload"),
                  let payload = try? JSONDecoder().decode(SharePayload.self, from: data) else { return }
            
            await MainActor.run {
                defaults.removeObject(forKey: "pendingSharePayload")
                self.startProcessing(with: payload)
            }
        }
    }

    func toggleSave(reelId: String) {
        if savedReelIds.contains(reelId) {
            savedReelIds.remove(reelId)
        } else {
            savedReelIds.insert(reelId)
        }
    }

    func isSaved(reelId: String) -> Bool {
        savedReelIds.contains(reelId)
    }

    func clearError() {
        errorMessage = nil
        showError = false
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack {
            DesignSystem.Colors.background
                .ignoresSafeArea()

            TabView(selection: Binding(
                get: { appState.selectedTab },
                set: { appState.selectTab($0) }
            )) {
                NavigationStack {
                    homeContent
                        .background(DesignSystem.Colors.background)
                        .navigationDestination(isPresented: $appState.showDiscovery, destination: { discoveryDestination })
                        .navigationDestination(isPresented: $appState.showGroupDetail, destination: { groupDestination })
                        .navigationDestination(isPresented: $appState.showSourceDetail, destination: { sourceDestination })
                }
                .tabItem { Label("Home", systemImage: "sparkles") }
                .tag(0)

                NavigationStack {
                    CollectionsView(
                        groups: appState.currentResponse?.groups ?? [],
                        reels: appState.currentResponse?.reels ?? [],
                        onGroupSelected: { appState.selectGroup($0) }
                    )
                        .background(DesignSystem.Colors.background)
                        .navigationDestination(isPresented: $appState.showDiscovery, destination: { discoveryDestination })
                        .navigationDestination(isPresented: $appState.showGroupDetail, destination: { groupDestination })
                }
                .tabItem { Label("Collections", systemImage: "square.grid.2x2.fill") }
                .tag(1)

                NavigationStack {
                    SavedView(
                        reels: appState.savedReels,
                        onReelSelected: { appState.selectReel($0) },
                        onUnsave: { appState.toggleSave(reelId: $0) }
                    )
                        .background(DesignSystem.Colors.background)
                        .navigationDestination(isPresented: $appState.showDiscovery, destination: { discoveryDestination })
                }
                .tabItem { Label("Saved", systemImage: "bookmark.fill") }
                .tag(2)
            }
            .background(.clear)
            .tint(DesignSystem.Palette.lime.resolved(in: .light))
            .sensoryFeedback(.selection, trigger: appState.selectedTab)
            .tabPersonality(selection: Binding(
                get: { appState.selectedTab },
                set: { appState.selectTab($0) }
            ))
            .saveFlightOverlay(appState: appState)
            .sheet(isPresented: $appState.showProcessing) {
                if let state = appState.processingState {
                    ProcessingView(
                        state: .constant(state),
                        onComplete: { appState.completeProcessing() },
                        onRetry: { appState.retryProcessing() }
                    )
                }
            }
            .alert("Error", isPresented: $appState.showError) {
                Button("OK") { appState.clearError() }
            } message: {
                Text(appState.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    @ViewBuilder
    private var homeContent: some View {
        if let response = appState.currentResponse {
            HomeView(
                response: response,
                onReelSelected: { appState.selectReel($0) },
                onGroupSelected: { appState.selectGroup($0) },
                onSourceSelected: { appState.selectSource($0) }
            )
        } else if appState.isLoading {
            ProgressView("Loading discoveries…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = appState.errorMessage {
            ContentUnavailableView {
                Label("Couldn't load discoveries", systemImage: "exclamationmark.arrow.circlepath")
            } description: {
                Text(error)
            } actions: {
                Button("Try Again") {
                    appState.loadHome()
                }
                .buttonStyle(.borderedProminent)
            }
        } else {
            ContentUnavailableView(
                "No discoveries yet",
                systemImage: "sparkles",
                description: Text("Share a reel from Instagram, TikTok, or YouTube to ReelScout to get started.")
            )
        }
    }

    @ViewBuilder
    private var discoveryDestination: some View {
        if let reel = appState.selectedReel {
            DiscoveryResultView(
                reel: reel,
                isSaved: appState.isSaved(reelId: reel.id),
                groupNames: appState.groupNames(for: reel),
                relatedReels: appState.relatedReels(for: reel),
                onSave: { appState.toggleSave(reelId: reel.id) },
                onShare: {},
                onOpenURL: { url in
                    if let url = URL(string: url) {
                        UIApplication.shared.open(url)
                    }
                },
                onReelSelected: { appState.selectReel($0) }
            )
        }
    }

    @ViewBuilder
    private var groupDestination: some View {
        if let group = appState.selectedGroup {
CollectionDetailView(
                collection: group,
                reels: appState.reels(in: group),
                onReelSelected: { appState.selectReel($0) }
            )
        }
    }

    @ViewBuilder
    private var sourceDestination: some View {
        if let source = appState.selectedSource {
            SourceDetailView(
                source: source,
                reels: appState.reels(in: source),
                onReelSelected: { appState.selectReel($0) }
            )
        }
    }
}
