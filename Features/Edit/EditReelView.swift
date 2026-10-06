import SwiftUI

/// Lets the user correct anything Kept extracted. This is the ONLY way
/// content changes in the app — there is no separate add/drop-reel UI.
struct EditReelView: View {
    @EnvironmentObject var store: ReelStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingDelete = false
    let reelID: UUID

    @State private var title = ""
    @State private var author = ""
    @State private var category = "Food"
    @State private var gist = ""
    @State private var points: [KeepPoint] = []
    @State private var placeName = ""
    @State private var placeSubtitle = ""
    @State private var mapURL = ""
    @State private var original: Reel?

    private let categories = ["Food", "Travel", "Fitness", "Home", "Tech", "Shopping", "Learning", "Entertainment"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") { TextField("Title", text: $title) }
                Section("Source") {
                    TextField("Author / account", text: $author)
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                }
                Section("The gist") { TextEditor(text: $gist).frame(minHeight: 90) }
                Section("Worth remembering") {
                    ForEach($points) { $point in
                        HStack { TextField("Point", text: $point.text) }
                    }
                    .onDelete { points.remove(atOffsets: $0) }
                    Button { points.append(.init(text: "")) } label: { Label("Add a point", systemImage: "plus") }
                }
                Section("Location") {
                    TextField("Place name", text: $placeName)
                    TextField("Neighborhood / subtitle", text: $placeSubtitle)
                    TextField("https://maps...", text: $mapURL)
                    if !mapURL.isEmpty {
                        Label("Found a location", systemImage: "checkmark.circle.fill").foregroundStyle(Theme.success).font(Theme.Font.body(13, weight: .semibold))
                    }
                    if !placeName.isEmpty || !mapURL.isEmpty {
                        Button(role: .destructive) {
                            placeName = ""; placeSubtitle = ""; mapURL = ""
                        } label: {
                            Label("Remove location", systemImage: "mappin.slash")
                        }
                    }
                }
                if let original {
                    Section {
                        Button("Reset to what Kept found") { load(original) }
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
                Section {
                    Button(role: .destructive) { confirmingDelete = true } label: {
                        Label("Delete reel from Kept", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Edit details")
            .navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Delete this reel from Kept?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete reel", role: .destructive) {
                    if let reel = store.reels.first(where: { $0.id == reelID }) { store.remove(reel) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("It is removed from this phone. You can add it again later.")
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Done") { save(); dismiss() } }
            }
            .onAppear {
                if let reel = store.reels.first(where: { $0.id == reelID }) {
                    original = reel
                    load(reel)
                }
            }
        }
    }

    private func load(_ reel: Reel) {
        title = reel.title ?? ""
        author = reel.author
        category = reel.category
        gist = reel.gist ?? ""
        points = reel.points
        placeName = reel.place?.name ?? ""
        placeSubtitle = reel.place?.subtitle ?? ""
        mapURL = reel.place?.mapURL ?? ""
    }

    private func save() {
        guard var reel = store.reels.first(where: { $0.id == reelID }) else { return }
        reel.title = title
        reel.author = author
        reel.category = category
        reel.gist = gist
        reel.points = points
        if placeName.isEmpty && mapURL.isEmpty {
            reel.place = nil
            reel.extraPlaces = nil
        } else {
            let existing = reel.place
            let name = placeName.isEmpty ? "Pinned location" : placeName
            // Keep verified coordinates only while the place name is unchanged.
            let keepsCoordinates = existing?.name == name
            reel.place = ReelPlace(
                id: existing?.id ?? UUID(),
                name: name,
                subtitle: placeSubtitle,
                mapURL: mapURL,
                latitude: keepsCoordinates ? existing?.latitude : nil,
                longitude: keepsCoordinates ? existing?.longitude : nil
            )
        }
        store.update(reel)
    }
}
