import SwiftUI

struct SaveBurst: View {
    let trigger: Int

    @State private var particles: [Particle] = []
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
                    .scaleEffect(particle.scale)
            }
        }
        .onChange(of: trigger) { _, _ in
            emit()
        }
    }

    private func emit() {
        particles = (0..<12).map { _ in Particle() }
        withAnimation(.easeOut(duration: 0.7)) {
            for i in particles.indices {
                particles[i].position = particles[i].target
                particles[i].opacity = 0
                particles[i].scale = 0.3
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            particles = []
        }
    }

    private struct Particle: Identifiable {
        let id = UUID()
        var position = CGPoint(x: 0, y: 0)
        var target = CGPoint.zero
        let size = CGFloat.random(in: 3...6)
        let color: SwiftUI.Color = [Color(hex: "A8D600"), Color(hex: "E86C5C"), Color(hex: "B8A8E8")].randomElement()!
        var opacity = 1.0
        var scale = 1.0

        init() {
            let angle = Double.random(in: 0..<2 * .pi)
            let distance = Double.random(in: 18...38)
            target = CGPoint(
                x: cos(angle) * distance,
                y: sin(angle) * distance
            )
        }
    }
}

struct SaveEffect<Content: View>: View {
    let content: Content
    let trigger: Int

    @State private var isAnimating = false

    var body: some View {
        content
            .overlay(alignment: .center) {
                if isAnimating {
                    SaveBurst(trigger: trigger)
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: trigger) { _, _ in
                isAnimating = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    isAnimating = false
                }
            }
    }
}

extension View {
    func saveBurst(trigger: Int) -> some View {
        SaveEffect(content: self, trigger: trigger)
    }
}