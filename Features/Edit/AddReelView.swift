import SwiftUI
import UIKit

/// Paste a reel or post link, any web page, a Google search link, or some text. Same path as the share sheet.
struct AddReelView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    @State private var input = ""
    @FocusState private var focused: Bool

    private enum Kind { case reel, page, text }

    private var kind: Kind? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if AppGroup.isSupportedLink(trimmed) { return .reel }
        if AppGroup.isWebLink(trimmed) { return .page }
        return trimmed.count >= 12 ? .text : nil
    }

    private var hint: String {
        switch kind {
        case .reel: return "A reel or post. Kept will download it, watch it and keep what matters."
        case .page: return "A web page or Google result. Kept will read it and pull out events and key facts."
        case .text: return "Text. Kept will pull out events, places and key facts."
        case nil: return "Paste a reel or post link, a web page, a Google search link, or some text."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text("Add to Kept").font(Theme.Font.display(32))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36).background(Theme.surface2, in: Circle())
                }
                .foregroundStyle(Theme.text)
            }

            if let quota = store.quota, let limit = quota.limit {
                Button { dismiss(); store.showingPlans = true } label: {
                    HStack {
                        Label("\(quota.remaining ?? 0) of \(limit) left this month", systemImage: "ticket")
                            .font(Theme.Font.body(13, weight: .semibold))
                        Spacer()
                        Text("Plans").font(Theme.Font.body(13, weight: .semibold)).foregroundStyle(Theme.aiFg)
                    }
                    .padding(.horizontal, 14).frame(height: 44)
                    .background(Theme.aiBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .foregroundStyle(Theme.text)
            }

            TextField("Link or text", text: $input, axis: .vertical)
                .font(Theme.Font.body(15))
                .lineLimit(1...5)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focused)
                .padding(14)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(hint).font(Theme.Font.body(13)).foregroundStyle(Theme.textSecondary)

            Button {
                if let pasted = UIPasteboard.general.string { input = pasted }
            } label: {
                Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                    .font(Theme.Font.body(14, weight: .semibold))
                    .padding(.horizontal, 16).frame(height: 40)
                    .background(Theme.surface2, in: Capsule())
            }
            .foregroundStyle(Theme.text)

            Spacer()

            Button(action: add) {
                Text("Read this").font(Theme.Font.body(16, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(kind == nil ? Theme.textSecondary.opacity(0.35) : Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .disabled(kind == nil)
        }
        .padding(20)
        .background(Theme.background)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { focused = false })
        .onAppear {
            focused = true
            // Pre-fill when the clipboard already holds a link.
            if input.isEmpty, UIPasteboard.general.hasURLs, let pasted = UIPasteboard.general.string { input = pasted }
        }
    }

    private func add() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        switch kind {
        case .reel, .page: store.ingest(sourceURL: trimmed)
        case .text: store.ingest(text: trimmed)
        case nil: return
        }
        dismiss()
    }
}
