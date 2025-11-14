# Renderererr

This repository contains experimental Python scripts. The main addition is
`toycc.py`, a minimal C compiler written in Python that targets 64-bit Windows.
It supports a very small subset of C consisting of a single `main` function with
integer arithmetic expressions.

## Usage

1. Write a simple C file, for example `test.c`:

   ```c
   int main() {
       return 2 + 3 * 4;
   }
   ```

2. Run the compiler to generate NASM-style assembly:

   ```bash
   python toycc.py test.c output.asm
   ```

3. Assemble and link the output using `nasm` and a linker capable of producing
   Windows executables. For example, with the [MinGW](http://www.mingw.org/) tool
   chain on Windows:

   ```bash
   nasm -f win64 output.asm -o output.obj
   gcc output.obj -o test.exe
   ```

The resulting `test.exe` will exit with the value computed in the `return`
statement. Only very basic integer expressions are supported.

## SwiftPhysicsEngine

This repository also includes **SwiftPhysicsEngine**, a minimal 2D physics engine written in Swift. The engine is designed for educational purposes and showcases how to implement vectors, rigid bodies, collision detection, and impulse resolution.

### Building and Testing

Run the unit tests using Swift Package Manager:

```bash
swift test
```

### Example Usage

```
import SwiftPhysicsEngine

let world = World()
let body = Body(position: Vec2(x: 0, y: 10), mass: 1)
let shape = PhysicsBodyComponent(rigidBody: body, shape: PhysicsCircle(radius: 1))
world.addBody(shape)
world.step(deltaTime: 1.0)
print(body.position)
```

This will simulate a single step with gravity acting on the body.

## Interface Builder for Web Apps

Need to sketch product dashboards or marketing pages without hand-writing HTML
every time? The repository now ships with `web_interface_builder.py`, a tiny
interface builder that turns JSON layout descriptions into static HTML.

### Usage

1. Describe your layout in JSON. The `Examples/dashboard_layout.json` file shows
   a full specification including theming, reusable class selectors, and nested
   components.
2. Run the builder to turn the JSON into HTML:

   ```bash
   python web_interface_builder.py Examples/dashboard_layout.json build/dashboard.html
   ```

   If you omit the second argument the script will emit an `.html` file next to
   your JSON spec automatically.
3. Open the generated HTML in a browser to review the interface, tweak the JSON
   as needed, and regenerate.

Supported component types today include `container`, `text`, `button`, `input`,
and `image`. Each component can opt into inline styles, extra attributes (for
ARIA labels, test hooks, etc.), and nested children to approximate the behavior
of visual interface builders.
