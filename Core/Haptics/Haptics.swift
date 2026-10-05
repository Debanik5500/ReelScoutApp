import SwiftUI
import UIKit

enum Haptics {
    private static var lastImpactTime: Date = .distantPast
    private static let minimumImpactInterval: TimeInterval = 0.08

    static func tap() {
        triggerImpact(.light)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func magneticPull() {
        triggerImpact(.medium)
    }

    static func magneticSnap() {
        triggerImpact(.heavy)
    }

    static func cardPress() {
        triggerImpact(.light)
    }

    static func cardRelease() {
        triggerImpact(.medium)
    }

    static func pileOpen() {
        triggerImpact(.medium)
    }

    static func pileClose() {
        triggerImpact(.light)
    }

    static func bookmark() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred(intensity: 0.7)
    }

    static func dropZoneEnter() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: 0.6)
    }

    static func dropZoneSuccess() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred(intensity: 0.8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    static func processingComplete() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func discoveryReveal() {
        triggerImpact(.light)
    }

    static func cardSnap() {
        triggerImpact(.medium)
    }

    private static func triggerImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let now = Date()
        guard now.timeIntervalSince(lastImpactTime) >= minimumImpactInterval else { return }
        lastImpactTime = now
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

extension View {
    func sensoryTap() -> some View {
        self.onTapGesture {
            Haptics.tap()
        }
    }

    func sensorySelection() -> some View {
        self.onTapGesture {
            Haptics.selection()
        }
    }
}