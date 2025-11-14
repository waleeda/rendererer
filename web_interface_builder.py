#!/usr/bin/env python3
"""Simple interface builder for web applications.

This script consumes a JSON layout description and produces a static HTML file
that reflects the described user interface. The workflow mirrors a lightweight
"interface builder" experience for web apps, letting teams tweak structured
layout primitives without hand-authoring repetitive markup.
"""

from __future__ import annotations

import argparse
import html
import json
from pathlib import Path
from typing import Any, Iterable, List, Mapping, MutableMapping

Component = Mapping[str, Any]
LayoutSpec = Mapping[str, Any]

SUPPORTED_COMPONENTS = {
    "container",
    "text",
    "button",
    "input",
    "image",
}


def camel_to_kebab(value: str) -> str:
    result: List[str] = []
    for char in value:
        if char.isupper():
            result.append("-")
            result.append(char.lower())
        else:
            result.append(char)
    return "".join(result)


def build_style_string(styles: Mapping[str, Any] | None) -> str | None:
    if not styles:
        return None
    css_chunks = []
    for key, value in styles.items():
        if value is None:
            continue
        css_chunks.append(f"{camel_to_kebab(key)}: {value}")
    return "; ".join(css_chunks) if css_chunks else None


def build_action_attributes(component: Component) -> MutableMapping[str, str]:
    actions = component.get("actions")
    attr_map: MutableMapping[str, str] = {}
    if not actions:
        return attr_map
    if not isinstance(actions, list):
        raise ValueError("Component actions must be a list of objects")
    for action in actions:
        if not isinstance(action, Mapping):
            raise ValueError("Each action entry must be a mapping")
        event = action.get("event")
        handler = action.get("handler")
        if not event or not handler:
            raise ValueError("Action entries require 'event' and 'handler' keys")
        event_attr = f"on{str(event).strip().lower()}"
        args = action.get("arguments", [])
        if args and not isinstance(args, list):
            raise ValueError("Action arguments must be a list of JavaScript expressions")
        arg_list = ["event", "this"] + [str(arg) for arg in args]
        attr_map[event_attr] = f"{handler}({', '.join(arg_list)})"
    return attr_map


def build_attributes(component: Component) -> str:
    attrs: MutableMapping[str, str] = {}
    if component.get("id"):
        attrs["id"] = str(component["id"])
    if component.get("className"):
        attrs["class"] = str(component["className"])
    if component.get("attributes"):
        for key, value in component["attributes"].items():
            if value is not None:
                attrs[key] = str(value)
    action_attrs = build_action_attributes(component)
    attrs.update(action_attrs)
    style_string = build_style_string(component.get("styles"))
    if style_string:
        attrs["style"] = style_string
    attr_chunks = [f'{key}="{html.escape(value, quote=True)}"' for key, value in attrs.items()]
    return (" " + " ".join(attr_chunks)) if attr_chunks else ""


def render_component(component: Component, indent: int = 4) -> str:
    component_type = component.get("type")
    if component_type not in SUPPORTED_COMPONENTS:
        raise ValueError(f"Unsupported component type: {component_type}")

    indent_str = " " * indent
    attributes = build_attributes(component)

    if component_type == "container":
        children = component.get("children", [])
        if not isinstance(children, list):
            raise ValueError("Container children must be a list of components")
        if not children:
            return f"{indent_str}<div{attributes}></div>"
        rendered_children = "\n".join(
            render_component(child, indent=indent + 2) for child in children
        )
        return f"{indent_str}<div{attributes}>\n{rendered_children}\n{indent_str}</div>"

    if component_type == "text":
        tag = component.get("tag", "p")
        text_content = html.escape(str(component.get("text", "")))
        return f"{indent_str}<{tag}{attributes}>{text_content}</{tag}>"

    if component_type == "button":
        label = html.escape(str(component.get("text", "Button")))
        return f"{indent_str}<button{attributes}>{label}</button>"

    if component_type == "input":
        placeholder = component.get("placeholder")
        placeholder_attr = (
            f' placeholder="{html.escape(str(placeholder))}"' if placeholder else ""
        )
        base = f"{indent_str}<input{attributes}{placeholder_attr}"
        if component.get("selfClosing", True):
            return base + " />"
        return base + "></input>"

    if component_type == "image":
        src = html.escape(str(component.get("src", "")))
        alt = html.escape(str(component.get("alt", "")))
        return f"{indent_str}<img src=\"{src}\" alt=\"{alt}\"{attributes} />"

    raise ValueError(f"Unhandled component type: {component_type}")


def render_body(components: Iterable[Component]) -> str:
    rendered = [render_component(component) for component in components]
    return "\n".join(rendered)


def build_theme_css(theme: Mapping[str, Any] | None) -> str:
    if not theme:
        return ""

    body_styles = build_style_string(theme.get("body"))
    css_blocks = []
    if body_styles:
        css_blocks.append(f"body {{ {body_styles}; }}")
    if theme.get("components"):
        for selector, style_dict in theme["components"].items():
            style_string = build_style_string(style_dict)
            if style_string:
                css_blocks.append(f"{selector} {{ {style_string}; }}")
    return "\n".join(css_blocks)


def build_scripts(scripts: Iterable[Any] | None) -> str:
    if not scripts:
        return ""
    rendered: List[str] = []
    for script in scripts:
        if isinstance(script, str):
            rendered.append(f"<script>\n{script}\n</script>")
            continue
        if not isinstance(script, Mapping):
            raise ValueError("Script entries must be strings or mappings")
        if script.get("src"):
            attrs = [f'src="{html.escape(str(script["src"]), quote=True)}"']
            if script.get("type"):
                attrs.append(f'type="{html.escape(str(script["type"]), quote=True)}"')
            rendered.append(f"<script {' '.join(attrs)}></script>")
            continue
        if script.get("code"):
            attrs = []
            if script.get("type"):
                attrs.append(f'type="{html.escape(str(script["type"]), quote=True)}"')
            attr_str = (" " + " ".join(attrs)) if attrs else ""
            rendered.append(f"<script{attr_str}>\n{script['code']}\n</script>")
            continue
        raise ValueError("Script objects require either 'src' or 'code'")
    return "\n  ".join(rendered)


def generate_html(spec: LayoutSpec) -> str:
    title = html.escape(str(spec.get("title", "Interface Builder Page")))
    components = spec.get("components", [])
    theme_css = build_theme_css(spec.get("theme"))
    custom_css = spec.get("customCss", "")
    stylesheets = spec.get("stylesheets", [])
    scripts = spec.get("scripts", [])

    head_parts = [f"<title>{title}</title>"]
    for sheet in stylesheets:
        head_parts.append(
            f'<link rel="stylesheet" href="{html.escape(str(sheet), quote=True)}">'
        )
    inline_css_blocks = [block for block in (theme_css, custom_css) if block]
    if inline_css_blocks:
        head_parts.append("<style>\n" + "\n".join(inline_css_blocks) + "\n</style>")

    head_html = "\n    ".join(head_parts)
    body_html = render_body(components)
    body_block = ("\n" + body_html + "\n  ") if body_html else ""
    script_block = build_scripts(scripts)
    trailing_scripts = ("  " + script_block + "\n") if script_block else ""

    return (
        "<!DOCTYPE html>\n"
        "<html lang=\"en\">\n"
        "  <head>\n"
        f"    {head_html}\n"
        "  </head>\n"
        "  <body>"
        f"{body_block}"
        "\n"
        f"{trailing_scripts}"
        "  </body>\n"
        "</html>\n"
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate static HTML layouts from JSON specifications."
    )
    parser.add_argument("spec", type=Path, help="Path to the JSON layout description.")
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        help=(
            "Optional path to the HTML file. Defaults to replacing the spec extension with .html."
        ),
    )
    return parser.parse_args()


def load_spec(path: Path) -> LayoutSpec:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise SystemExit(f"Unable to parse {path}: {exc}") from exc


def main() -> None:
    args = parse_args()
    spec_path: Path = args.spec
    if not spec_path.exists():
        raise SystemExit(f"Spec file {spec_path} does not exist.")

    spec = load_spec(spec_path)
    html_output = generate_html(spec)
    output_path = args.output or spec_path.with_suffix(".html")
    output_path.write_text(html_output, encoding="utf-8")
    print(f"Generated {output_path} from {spec_path}")


if __name__ == "__main__":
    main()
