import Foundation

public protocol Shape {}

public struct Circle: Shape {
    public var radius: Double
    public init(radius: Double) {
        self.radius = radius
    }
}

public struct AABB: Shape {
    public var halfWidth: Double
    public var halfHeight: Double
    public init(halfWidth: Double, halfHeight: Double) {
        self.halfWidth = halfWidth
        self.halfHeight = halfHeight
    }
}
