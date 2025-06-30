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
