import Foundation

public class PhysicsBody {
    public var rigidBody: RigidBody
    public var shape: Shape

    public init(rigidBody: RigidBody, shape: Shape) {
        self.rigidBody = rigidBody
        self.shape = shape
    }
}

public class PhysicsWorld {
    public var bodies: [PhysicsBody] = []
    public var gravity: Vector2 = Vector2(x: 0, y: -9.8)

    public init() {}

    public func addBody(_ body: PhysicsBody) {
        bodies.append(body)
    }

    public func step(deltaTime: Double) {
        // Apply gravity
        for body in bodies {
            body.rigidBody.applyForce(gravity * body.rigidBody.mass)
        }

        // Integrate
        for body in bodies {
            body.rigidBody.integrate(deltaTime: deltaTime)
        }

        // Collision detection and resolution
        let count = bodies.count
        for i in 0..<count {
            for j in i+1..<count {
                handleCollision(bodyA: bodies[i], bodyB: bodies[j])
            }
        }
    }

    private func handleCollision(bodyA: PhysicsBody, bodyB: PhysicsBody) {
        if let circleA = bodyA.shape as? Circle, let circleB = bodyB.shape as? Circle {
            if let manifold = Collision.circleVsCircle(posA: bodyA.rigidBody.position, radA: circleA.radius, posB: bodyB.rigidBody.position, radB: circleB.radius) {
                resolve(manifold: manifold, bodyA: bodyA.rigidBody, bodyB: bodyB.rigidBody)
            }
        } else if let boxA = bodyA.shape as? AABB, let boxB = bodyB.shape as? AABB {
            if let manifold = Collision.aabbVsAabb(posA: bodyA.rigidBody.position, boxA: boxA, posB: bodyB.rigidBody.position, boxB: boxB) {
                resolve(manifold: manifold, bodyA: bodyA.rigidBody, bodyB: bodyB.rigidBody)
            }
        }
    }

    private func resolve(manifold: Manifold, bodyA: RigidBody, bodyB: RigidBody) {
        guard let contact = manifold.contacts.first else { return }
        let relativeVelocity = bodyB.velocity - bodyA.velocity
        let velocityAlongNormal = relativeVelocity.x * contact.normal.x + relativeVelocity.y * contact.normal.y
        if velocityAlongNormal > 0 { return }

        let restitution = min(bodyA.restitution, bodyB.restitution)
        let j = -(1 + restitution) * velocityAlongNormal / (bodyA.inverseMass + bodyB.inverseMass)
        let impulse = contact.normal * j
        bodyA.velocity.add(impulse * -bodyA.inverseMass)
        bodyB.velocity.add(impulse * bodyB.inverseMass)

        // Positional correction
        let percent = 0.8
        let slop = 0.01
        let correctionMagnitude = max(contact.penetration - slop, 0) / (bodyA.inverseMass + bodyB.inverseMass) * percent
        let correction = contact.normal * correctionMagnitude
        bodyA.position.add(correction * -bodyA.inverseMass)
        bodyB.position.add(correction * bodyB.inverseMass)
    }
}
