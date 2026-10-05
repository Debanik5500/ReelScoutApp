import SwiftUI

struct ScrollReveal<Content: View>: View {
    let content: Content
    let threshold: CGFloat

    @State private var hasAppeared = false
    @State private var didEnter = false

    init(_ content: Content, threshold: CGFloat = 200) {
        self.content = content
        self.threshold = threshold
    }

    var body: some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared ? 0 : 16)
            .blur(radius: hasAppeared ? 0 : 4)
            .animation(Motion.smooth.animation.delay(0.08), value: hasAppeared)
            .onScrollVisibilityChange(threshold: threshold) { visible in
                if visible && !didEnter {
                    didEnter = true
                    withAnimation(Motion.smooth.animation.delay(0.08)) {
                        hasAppeared = true
                    }
                }
            }
    }
}

struct ScrollRevealHorizontal<Content: View>: View {
    let content: Content
    let threshold: CGFloat

    @State private var hasAppeared = false
    @State private var didEnter = false

    init(_ content: Content, threshold: CGFloat = 100) {
        self.content = content
        self.threshold = threshold
    }

    var body: some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(x: hasAppeared ? 0 : 24)
            .blur(radius: hasAppeared ? 0 : 4)
            .animation(Motion.smooth.animation.delay(0.08), value: hasAppeared)
            .onScrollVisibilityChangeHorizontal(threshold: threshold) { visible in
                if visible && !didEnter {
                    didEnter = true
                    withAnimation(Motion.smooth.animation.delay(0.08)) {
                        hasAppeared = true
                    }
                }
            }
    }
}

extension View {
    func scrollReveal(threshold: CGFloat = 200) -> some View {
        ScrollReveal(self, threshold: threshold)
    }

    func scrollRevealHorizontal(threshold: CGFloat = 100) -> some View {
        ScrollRevealHorizontal(self, threshold: threshold)
    }
}

struct ScrollVisibilityKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

struct HorizontalScrollVisibilityKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}

extension View {
    func onScrollVisibilityChange(threshold: CGFloat = 200, _ action: @escaping (Bool) -> Void) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: ScrollVisibilityKey.self,
                               value: proxy.frame(in: .global).maxY > -threshold &&
                                     proxy.frame(in: .global).minY < UIScreen.main.bounds.height + threshold)
            }
        )
        .onPreferenceChange(ScrollVisibilityKey.self, perform: action)
    }

    func onScrollVisibilityChangeHorizontal(threshold: CGFloat = 100, _ action: @escaping (Bool) -> Void) -> some View {
        self.background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: HorizontalScrollVisibilityKey.self,
                               value: proxy.frame(in: .global).maxX > -threshold &&
                                     proxy.frame(in: .global).minX < UIScreen.main.bounds.width + threshold)
            }
        )
        .onPreferenceChange(HorizontalScrollVisibilityKey.self, perform: action)
    }
}