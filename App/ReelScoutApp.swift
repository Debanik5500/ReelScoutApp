import SwiftUI

@main
struct KeptApp: App {
    @StateObject private var store = ReelStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .onOpenURL { url in
                    // Share-extension hand-off: kept://share?url=<instagram-reel-url>
                    if url.scheme == "kept", url.host == "share",
                       let shared = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                           .queryItems?.first(where: { $0.name == "url" })?.value {
                        store.ingest(sourceURL: shared)
                    }
                }
        }
    }
}

struct RootView: View {
    @EnvironmentObject var store: ReelStore

    var body: some View {
        TabView {
            NavigationStack { LibraryView() }
                .tabItem { Label("Library", systemImage: "square.grid.2x2.fill") }
            NavigationStack { SavedStackView() }
                .tabItem { Label("Shuffle", systemImage: "rectangle.stack.fill") }
            NavigationStack { PlacesView() }
                .tabItem { Label("Places", systemImage: "mappin.and.ellipse") }
        }
        .tint(Theme.accent)
        .sheet(isPresented: $store.showingPlans) { SubscribeView() }
        .onAppear { store.ingestPendingShareIfAny() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            store.ingestPendingShareIfAny()
        }
    }
}
