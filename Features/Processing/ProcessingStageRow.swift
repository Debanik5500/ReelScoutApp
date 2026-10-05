import SwiftUI

/// Six small pips instead of a checklist — presence, not paperwork.
struct ProcessingPips: View {
    let stage: ProcessingStage

    private var stages: [ProcessingStage] {
        [.watching, .listening, .identifying, .lookingUp, .enriching, .organizing]
    }

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(Array(stages.enumerated()), id: \.element) { index, pip in
                let status = pipStatus(pip, index: index)
                Capsule()
                    .fill(fill(for: status))
                    .frame(width: status == .active ? 22 : 8, height: 8)
                    .animation(Motion.standard.animation, value: status)
            }
        }
        .accessibilityLabel("\(doneCount) of \(stages.count) steps done")
    }

    private enum Status { case done, active, pending }

    private func pipStatus(_ pip: ProcessingStage, index: Int) -> Status {
        guard let currentIndex = stages.firstIndex(of: stage) else {
            return stage == .completed || stage == .failed ? .done : .pending
        }
        if stage == .failed { return index < currentIndex ? .done : .pending }
        if stage == .completed { return .done }
        if index < currentIndex { return .done }
        if index == currentIndex { return .active }
        return .pending
    }

    private func fill(for status: Status) -> SwiftUI.Color {
        switch status {
        case .done: return DesignSystem.Colors.lime
        case .active: return DesignSystem.Colors.lime.opacity(0.35)
        case .pending: return DesignSystem.Colors.subtleBorder
        }
    }

    private var doneCount: Int {
        guard let currentIndex = stages.firstIndex(of: stage) else { return 0 }
        if stage == .completed { return stages.count }
        return min(currentIndex, stages.count)
    }
}