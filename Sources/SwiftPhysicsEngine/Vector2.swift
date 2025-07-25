import Foundation

// Conform to Sendable so it can be safely used across concurrency domains

public struct Vector2: Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }

    public static let zero = Vector2()

    public static func +(lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    public static func -(lhs: Vector2, rhs: Vector2) -> Vector2 {
        Vector2(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    public static func *(lhs: Vector2, rhs: Double) -> Vector2 {
        Vector2(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    public static func /(lhs: Vector2, rhs: Double) -> Vector2 {
        Vector2(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    public mutating func add(_ other: Vector2) {
        x += other.x
        y += other.y
    }

    public mutating func scale(by scalar: Double) {
        x *= scalar
        y *= scalar
    }

    public var lengthSquared: Double {
        x * x + y * y
    }

    public var length: Double {
        sqrt(lengthSquared)
    }

    public func normalized() -> Vector2 {
        let len = length
        if len > 0 {
            return self / len
        }
        return .zero
    }
}
