# toycc.py - A minimal C compiler in Python for Windows

import re
import sys
from dataclasses import dataclass
from typing import List, Union

Token = Union[str, int]

# Simple lexer to tokenize integers, identifiers, and operators
TOKEN_REGEX = re.compile(r"\s*(?:(\d+)|([A-Za-z_][A-Za-z0-9_]*)|(.))")


@dataclass
class ASTNode:
    kind: str
    value: Union[int, str, None] = None
    left: "ASTNode" = None
    right: "ASTNode" = None


def tokenize(code: str) -> List[Token]:
    tokens: List[Token] = []
    for number, ident, op in TOKEN_REGEX.findall(code):
        if number:
            tokens.append(int(number))
        elif ident:
            tokens.append(ident)
        else:
            tokens.append(op)
    return tokens


def parse_expression(tokens: List[Token]) -> ASTNode:
    # Shunting-yard to parse expression into AST
    def precedence(op: str) -> int:
        return {"+": 1, "-": 1, "*": 2, "/": 2}.get(op, 0)

    output: List[ASTNode] = []
    ops: List[str] = []

    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if isinstance(tok, int):
            output.append(ASTNode("num", tok))
        elif tok in ("+", "-", "*", "/"):
            while ops and precedence(ops[-1]) >= precedence(tok):
                op = ops.pop()
                right = output.pop()
                left = output.pop()
                output.append(ASTNode("binop", op, left, right))
            ops.append(tok)
        elif tok == "(":
            ops.append(tok)
        elif tok == ")":
            while ops and ops[-1] != "(":
                op = ops.pop()
                right = output.pop()
                left = output.pop()
                output.append(ASTNode("binop", op, left, right))
            ops.pop()  # Remove "("
        i += 1

    while ops:
        op = ops.pop()
        right = output.pop()
        left = output.pop()
        output.append(ASTNode("binop", op, left, right))

    if len(output) != 1:
        raise SyntaxError("Invalid expression")
    return output[0]


def parse(tokens: List[Token]) -> ASTNode:
    # Expect pattern: int main() { return <expr>; }
    i = 0
    if tokens[i] != "int":
        raise SyntaxError("Expected 'int'")
    i += 1
    if tokens[i] != "main":
        raise SyntaxError("Expected 'main'")
    i += 1
    if tokens[i] != "(":
        raise SyntaxError("Expected '('")
    i += 1
    if tokens[i] != ")":
        raise SyntaxError("Expected ')'")
    i += 1
    if tokens[i] != "{":
        raise SyntaxError("Expected '{'")
    i += 1
    if tokens[i] != "return":
        raise SyntaxError("Expected 'return'")
    i += 1

    expr_tokens = []
    while tokens[i] != ";":
        expr_tokens.append(tokens[i])
        i += 1
    i += 1  # skip ';'

    if tokens[i] != "}":
        raise SyntaxError("Expected '}'")

    expr_ast = parse_expression(expr_tokens)
    return ASTNode("function", "main", expr_ast)


def compile_expression(node: ASTNode, asm: List[str]):
    if node.kind == "num":
        asm.append(f"    mov rax, {node.value}")
    elif node.kind == "binop":
        compile_expression(node.left, asm)
        asm.append("    push rax")
        compile_expression(node.right, asm)
        asm.append("    mov rbx, rax")
        asm.append("    pop rax")
        if node.value == "+":
            asm.append("    add rax, rbx")
        elif node.value == "-":
            asm.append("    sub rax, rbx")
        elif node.value == "*":
            asm.append("    imul rax, rbx")
        elif node.value == "/":
            asm.append("    cqo")
            asm.append("    idiv rbx")
        else:
            raise ValueError(f"Unknown operator {node.value}")
    else:
        raise ValueError(f"Unknown node kind {node.kind}")


def compile_to_asm(ast: ASTNode) -> str:
    asm: List[str] = ["global main", "section .text", "main:"]
    compile_expression(ast.left, asm)
    asm.append("    ret")
    return "\n".join(asm)


def main():
    if len(sys.argv) != 3:
        print("Usage: python toycc.py <input.c> <output.asm>")
        return

    with open(sys.argv[1]) as f:
        code = f.read()

    tokens = tokenize(code)
    ast = parse(tokens)
    asm_code = compile_to_asm(ast)

    with open(sys.argv[2], "w") as f:
        f.write(asm_code)
    print(f"Assembly written to {sys.argv[2]}")


if __name__ == "__main__":
    main()
