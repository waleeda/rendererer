import Foundation

public struct Contact {
    public var normal: Vector2
    public var penetration: Double
}

public struct Manifold {
    public var contacts: [Contact] = []
}

public class Collision {
    public static func circleVsCircle(posA: Vector2, radA: Double, posB: Vector2, radB: Double) -> Manifold? {
        let delta = posB - posA
        let dist2 = delta.lengthSquared
        let radiusSum = radA + radB
        if dist2 >= radiusSum * radiusSum {
            return nil
        }
        let distance = sqrt(dist2)
        let penetration = radiusSum - distance
        let normal = distance > 0 ? delta / distance : Vector2(x: 1, y: 0)
        return Manifold(contacts: [Contact(normal: normal, penetration: penetration)])
    }

    public static func aabbVsAabb(posA: Vector2, boxA: AABB, posB: Vector2, boxB: AABB) -> Manifold? {
        let diff = posB - posA
        let overlapX = boxA.halfWidth + boxB.halfWidth - abs(diff.x)
        if overlapX <= 0 { return nil }
        let overlapY = boxA.halfHeight + boxB.halfHeight - abs(diff.y)
        if overlapY <= 0 { return nil }

        if overlapX < overlapY {
            let normal = Vector2(x: diff.x < 0 ? -1 : 1, y: 0)
            return Manifold(contacts: [Contact(normal: normal, penetration: overlapX)])
        } else {
            let normal = Vector2(x: 0, y: diff.y < 0 ? -1 : 1)
            return Manifold(contacts: [Contact(normal: normal, penetration: overlapY)])
        }
    }
}
