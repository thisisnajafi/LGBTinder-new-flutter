#!/usr/bin/env python3
"""Migrate Text(maxLines + ellipsis) widgets to AppText across lib/."""

from __future__ import annotations

import re
import sys
from pathlib import Path

IMPORT_LINE = "import 'package:lgbtindernew/core/responsive/responsive.dart';\n"
IMPORT_PATH = "package:lgbtindernew/core/responsive/responsive.dart"
SKIP_DIRS = {"generated", ".dart_tool"}


def find_matching_paren(text: str, open_index: int) -> int:
    depth = 0
    i = open_index
    while i < len(text):
        ch = text[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return i
        elif ch in ("'", '"'):
            quote = ch
            i += 1
            while i < len(text):
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == quote:
                    break
                i += 1
        i += 1
    return -1


def should_skip_widget(widget: str) -> bool:
    if widget.startswith("Text.rich"):
        return True
    if "TextSpan" in widget:
        return True
    if "maxLines" not in widget:
        return True
    if "TextOverflow.ellipsis" not in widget:
        return True
    return False


def convert_widget(widget: str) -> str:
    converted = re.sub(r"\bconst\s+Text\s*\(", "const AppText(", widget, count=1)
    converted = re.sub(r"\bText\s*\(", "AppText(", converted, count=1)
    converted = re.sub(
        r",?\s*overflow:\s*TextOverflow\.ellipsis\b", "", converted
    )
    return converted


def process_content(content: str) -> tuple[str, int]:
    changes = 0
    result: list[str] = []
    i = 0
    length = len(content)

    while i < length:
        match = re.search(r"\bconst\s+Text\s*\(|\bText\s*\(", content[i:])
        if not match:
            result.append(content[i:])
            break

        start = i + match.start()
        result.append(content[i:start])

        open_paren = content.find("(", start)
        close_paren = find_matching_paren(content, open_paren)
        if close_paren < 0:
            result.append(content[start:])
            break

        widget = content[start : close_paren + 1]
        if should_skip_widget(widget):
            result.append(widget)
        else:
            result.append(convert_widget(widget))
            changes += 1

        i = close_paren + 1

    new_content = "".join(result)
    if changes and IMPORT_PATH not in new_content:
        if "/responsive/responsive.dart" not in new_content:
            new_content = add_import(new_content)

    return new_content, changes


def add_import(content: str) -> str:
    if IMPORT_PATH in content:
        return content

    lines = content.splitlines(keepends=True)
    last_import = 0
    for idx, line in enumerate(lines):
        if line.startswith("import "):
            last_import = idx + 1
    lines.insert(last_import, IMPORT_LINE)
    return "".join(lines)


def process_file(path: Path) -> int:
    original = path.read_text(encoding="utf-8")
    if "TextOverflow.ellipsis" not in original:
        return 0

    updated, changes = process_content(original)
    if changes == 0:
        return 0

    path.write_text(updated, encoding="utf-8")
    return changes


def main() -> int:
    root = Path(__file__).resolve().parents[1] / "lib"
    if not root.is_dir():
        print(f"lib not found: {root}", file=sys.stderr)
        return 1

    total_files = 0
    total_widgets = 0

    for path in sorted(root.rglob("*.dart")):
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.name == "responsive_text.dart":
            continue

        count = process_file(path)
        if count:
            total_files += 1
            total_widgets += count
            print(f"{path.relative_to(root.parent)}: {count}")

    print(f"\nDone: {total_widgets} widgets in {total_files} files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
