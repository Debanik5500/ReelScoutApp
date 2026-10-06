import SwiftUI

/// Full-screen photo viewer for a reel's key moments: swipe sideways through all of them, pinch or double-tap to
/// zoom, drag down to close. `index` is shared with the caller, so the card stack behind lands on the same moment.
struct KeyMomentViewer: View {
    let moments: [KeyMoment]
    @Binding var index: Int
    @Environment(\.dismiss) private var dismiss
    @State private var position: Int?
    @State private var dragY: CGFloat = 0
    /// Decided once per drag: a vertical drag closes the viewer, anything else belongs to the pager.
    @State private var dragIsVertical: Bool?

    init(moments: [KeyMoment], index: Binding<Int>) {
        self.moments = moments
        _index = index
        _position = State(initialValue: index.wrappedValue)
    }

    private var current: Int { min(max(position ?? index, 0), max(moments.count - 1, 0)) }

    var body: some View {
        ZStack {
            Color.black.opacity(1 - min(abs(dragY) / 500, 0.7)).ignoresSafeArea()

            // A plain paging scroll view: no gesture fight with the close-drag, and every page is already built,
            // so nothing pops in while swiping.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(moments.enumerated()), id: \.element.id) { page, moment in
                        ZoomableFrame(moment: moment)
                            .containerRelativeFrame(.horizontal)
                            .id(page)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $position)
            .ignoresSafeArea()
            .task { await warmImages() }

            VStack {
                topBar
                Spacer()
                caption
            }
            .opacity(1 - min(abs(dragY) / 200, 1))
            .allowsHitTesting(abs(dragY) < 1)
        }
        .offset(y: dragY)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    if dragIsVertical == nil {
                        dragIsVertical = abs(value.translation.height) > abs(value.translation.width) * 1.5
                    }
                    if dragIsVertical == true { dragY = value.translation.height }
                }
                .onEnded { value in
                    defer { dragIsVertical = nil }
                    guard dragIsVertical == true else { return }
                    if abs(dragY) > 120 || abs(value.predictedEndTranslation.height) > 450 {
                        dismiss()
                    } else {
                        withAnimation(Theme.Spring.snappy) { dragY = 0 }
                    }
                }
        )
        .onChange(of: position) { _, new in if let new { index = new } }
        .statusBarHidden()
    }

    /// Load every frame into memory up front so paging never waits on the network or disk.
    private func warmImages() async {
        for moment in moments {
            if let url = moment.frameURL, !url.isEmpty { _ = await ReelAPIClient.shared.loadImage(from: url) }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 16, weight: .semibold))
                    .frame(width: 44, height: 44).background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            Text("\(current + 1) / \(moments.count)")
                .font(Theme.Font.body(13, weight: .semibold))
                .padding(.horizontal, 14).frame(height: 36)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16).padding(.top, 8)
    }

    @ViewBuilder private var caption: some View {
        if let moment = moments[safe: current] {
            VStack(alignment: .leading, spacing: 6) {
                Text(moment.timestamp).font(Theme.Font.body(11, weight: .bold))
                    .padding(.horizontal, 8).padding(.vertical, 4).background(.white, in: Capsule())
                    .foregroundStyle(.black)
                Text(moment.label).font(Theme.Font.display(26)).foregroundStyle(.white)
                if !moment.note.isEmpty {
                    Text(moment.note).font(Theme.Font.body(14)).foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20).padding(.vertical, 18)
            .background(LinearGradient(colors: [.black.opacity(0.7), .clear], startPoint: .bottom, endPoint: .top))
        }
    }
}

/// One moment's frame, fitted to the screen. The page always fills the screen and the image fades in, so the
/// layout never jumps when it loads. Pinch or double-tap to zoom.
private struct ZoomableFrame: View {
    let moment: KeyMoment
    @State private var image: UIImage?
    @State private var scale: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    init(moment: KeyMoment) {
        self.moment = moment
        _image = State(initialValue: moment.frameURL.flatMap(ReelAPIClient.cachedImage))
    }

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().scaledToFit()
                    .scaleEffect(scale * pinch)
                    .gesture(
                        MagnificationGesture()
                            .updating($pinch) { value, state, _ in state = value }
                            .onEnded { value in withAnimation(Theme.Spring.snappy) { scale = min(max(scale * value, 1), 4) } }
                    )
                    .onTapGesture(count: 2) { withAnimation(Theme.Spring.snappy) { scale = scale > 1 ? 1 : 2.5 } }
                    .transition(.opacity)
            } else if moment.frameURL == nil || moment.frameURL?.isEmpty == true {
                Image.cover(moment.imageName).resizable().scaledToFit()
            } else {
                ProgressView().tint(.white)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeOut(duration: 0.2), value: image == nil)
        .task {
            if image == nil, let url = moment.frameURL, !url.isEmpty {
                image = await ReelAPIClient.shared.loadImage(from: url)
            }
        }
    }
}
