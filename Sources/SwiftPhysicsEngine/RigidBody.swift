import Foundation

public class RigidBody {
    public var position: Vector2
    public var velocity: Vector2
    public var force: Vector2 = .zero
    public var mass: Double
    public var inverseMass: Double
    public var restitution: Double

    public init(position: Vector2 = .zero, velocity: Vector2 = .zero, mass: Double = 1.0, restitution: Double = 0.5) {
        self.position = position
        self.velocity = velocity
        self.mass = mass
        self.restitution = restitution
        self.inverseMass = mass > 0 ? 1.0 / mass : 0.0
    }

    public func applyForce(_ f: Vector2) {
        force.add(f)
    }

    public func integrate(deltaTime: Double) {
        guard inverseMass > 0 else { return }
        // Update velocity from accumulated force
        let acceleration = force * inverseMass
        velocity.add(acceleration * deltaTime)
        // Update position from velocity
        position.add(velocity * deltaTime)
        // Reset force
        force = .zero
    }
}
