import SwiftUI
import UIKit

/// Paste a reel link to have Kept read it. Same path as the share extension: `ReelStore.ingest`.
struct AddReelView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    @State private var link = ""
    @FocusState private var focused: Bool

    private var url: String? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = URL(string: trimmed), let scheme = parsed.scheme?.lowercased(),
              ["http", "https"].contains(scheme), parsed.host != nil,
              AppGroup.isSupportedLink(trimmed) else { return nil }
        return trimmed
    }

    private var looksWrong: Bool {
        !link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && url == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Add a reel").font(Theme.Font.display(32))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36).background(Theme.surface2, in: Circle())
                }
                .foregroundStyle(Theme.text)
            }

            Text("Paste an Instagram reel link. Kept will download it, watch it and keep what matters.")
                .font(Theme.Font.body(14)).foregroundStyle(Theme.textSecondary)

            if let quota = store.quota, let limit = quota.limit {
                Button { dismiss(); store.showingPlans = true } label: {
                    HStack {
                        Label("\(quota.remaining ?? 0) of \(limit) reels left this month", systemImage: "ticket")
                            .font(Theme.Font.body(13, weight: .semibold))
                        Spacer()
                        Text("Plans").font(Theme.Font.body(13, weight: .semibold)).foregroundStyle(Theme.aiFg)
                    }
                    .padding(.horizontal, 14).frame(height: 44)
                    .background(Theme.aiBg, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .foregroundStyle(Theme.text)
            }

            HStack(spacing: 10) {
                Image(systemName: "link").foregroundStyle(Theme.textSecondary)
                TextField("https://www.instagram.com/reel/…", text: $link)
                    .font(Theme.Font.body(15))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .submitLabel(.go)
                    .onSubmit(add)
                if !link.isEmpty {
                    Button { link = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 14).frame(height: 52)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if looksWrong {
                Label("That doesn't look like a reel or post link", systemImage: "exclamationmark.triangle.fill")
                    .font(Theme.Font.body(12, weight: .semibold)).foregroundStyle(Theme.accentHighlight)
            }

            Button {
                if let pasted = UIPasteboard.general.string { link = pasted }
            } label: {
                Label("Paste from clipboard", systemImage: "doc.on.clipboard")
                    .font(Theme.Font.body(14, weight: .semibold))
                    .padding(.horizontal, 16).frame(height: 40)
                    .background(Theme.surface2, in: Capsule())
            }
            .foregroundStyle(Theme.text)

            Spacer()

            Button(action: add) {
                Text("Read this reel").font(Theme.Font.body(16, weight: .semibold))
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(url == nil ? Theme.textSecondary.opacity(0.35) : Theme.accent, in: Capsule())
                    .foregroundStyle(.white)
            }
            .disabled(url == nil)
        }
        .padding(20)
        .background(Theme.background)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded { focused = false })
        .onAppear {
            focused = true
            // Pre-fill when the clipboard already holds a link.
            if link.isEmpty, UIPasteboard.general.hasURLs || (UIPasteboard.general.string?.hasPrefix("http") ?? false),
               let pasted = UIPasteboard.general.string { link = pasted }
        }
    }

    private func add() {
        guard let url else { return }
        store.ingest(sourceURL: url)
        dismiss()
    }
}
