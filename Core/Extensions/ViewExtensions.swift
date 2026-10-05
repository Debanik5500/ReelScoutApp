import SwiftUI

extension View {
    @ViewBuilder
    func ifLet<T>(_ optional: T?, transform: (Self, T) -> some View) -> some View {
        if let value = optional {
            transform(self, value)
        } else {
            self
        }
    }

    @ViewBuilder
    func conditional<T>(_ condition: Bool, transform: (Self) -> T) -> some View where T: View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }

    static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
}