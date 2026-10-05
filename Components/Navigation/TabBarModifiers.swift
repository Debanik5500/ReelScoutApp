import SwiftUI

struct TabPersonalityWrapper<Content: View>: View {
    let content: Content
    @Binding var selection: Int
    @EnvironmentObject var appState: AppState

    var body: some View {
        content
            .safeAreaInset(edge: .bottom) {
                TabBarPersonality(
                    selection: Binding(
                        get: { Tab(rawValue: selection) ?? .home },
                        set: { selection = $0.rawValue }
                    ),
                    onSaveLanded: {
                        appState.savedTabPulse += 1
                    }
                )
            }
    }
}

extension View {
    func tabPersonality(selection: Binding<Int>) -> some View {
        TabPersonalityWrapper(content: self, selection: selection)
    }
}

struct SaveFlightOverlayWrapper<Content: View>: View {
    let content: Content

    var body: some View {
        ZStack {
            content
            SaveFlightOverlay()
        }
    }
}

extension View {
    func saveFlightOverlay(appState: AppState) -> some View {
        self.environmentObject(appState)
            .overlay {
                SaveFlightOverlay()
            }
    }
}

enum Tab: Int, CaseIterable {
    case home = 0
    case saved = 2
    case collections = 1
    case processing = 3

    var rawValue: Int {
        switch self {
        case .home: return 0
        case .collections: return 1
        case .saved: return 2
        case .processing: return 3
        }
    }

    init(rawValue: Int) {
        switch rawValue {
        case 0: self = .home
        case 1: self = .collections
        case 2: self = .saved
        case 3: self = .processing
        default: self = .home
        }
    }
}