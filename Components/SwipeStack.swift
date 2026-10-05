import SwiftUI

/// A generic tilted, swipeable stack. The design uses this shape twice:
/// the Shuffle stack (full reels) and Key moments (frames within a reel).
/// Exactly one generic component backs both, so the gesture and tilt math
/// live in a single place.
struct SwipeStack<Item: Identifiable, Content: View>: View {
    let items: [Item]
    @Binding var index: Int
    let cardWidth: CGFloat
    let cardHeight: CGFloat
    @ViewBuilder var content: (Item, Bool) -> Content // (item, isFront)

    @State private var dragX: CGFloat = 0

    private var count: Int { items.count }

    var body: some View {
        ZStack {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                let depth = (i - index + count) % count
                card(item, depth: depth)
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .gesture(
            DragGesture()
                .onChanged { dragX = $0.translation.width }
                .onEnded { value in
                    let dx = value.translation.width
                    withAnimation(Theme.Spring.standard) {
                        if dx < -30 { advance(1) }
                        else if dx > 30 { advance(-1) }
                        dragX = 0
                    }
                }
        )
        .onTapGesture { withAnimation(Theme.Spring.standard) { advance(1) } }
    }

    private func advance(_ delta: Int) {
        index = (index + delta + count) % count
    }

    @ViewBuilder
    private func card(_ item: Item, depth: Int) -> some View {
        let isFront = depth == 0
        let isLast = depth == count - 1
        let liveDrag = isFront ? dragX : 0

        content(item, isFront)
            .frame(width: cardWidth, height: cardHeight)
            .rotationEffect(.degrees(isLast ? -30 : -8 + Double(depth) * 7))
            .scaleEffect(isLast ? 1 : 1 - Double(depth) * 0.06)
            .offset(
                x: (isLast ? -430 : -46 + CGFloat(depth) * 36) + liveDrag,
                y: isLast ? 40 : CGFloat(depth) * 4
            )
            .opacity(isLast || depth > 3 ? 0 : 1)
            .zIndex(Double(count - depth))
            .animation(Theme.Spring.standard, value: depth)
    }
}
