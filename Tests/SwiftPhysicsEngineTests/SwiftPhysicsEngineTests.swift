import Testing
@testable import SwiftPhysicsEngine

@Test func simulationWorks() async throws {
    let world = World()
    world.gravity = Vec2(x: 0, y: -10)
    let bodyA = Body(position: Vec2(x: 0, y: 0), mass: 1.0)
    let bodyB = Body(position: Vec2(x: 0, y: 5), mass: 1.0)
    let circleA = PhysicsBodyComponent(rigidBody: bodyA, shape: PhysicsCircle(radius: 1))
    let circleB = PhysicsBodyComponent(rigidBody: bodyB, shape: PhysicsCircle(radius: 1))
    world.addBody(circleA)
    world.addBody(circleB)
    world.step(deltaTime: 1.0)
    #expect(bodyA.position.y < 0)
}
