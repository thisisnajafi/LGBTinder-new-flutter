#!/usr/bin/env python3
"""Remove duplicate package responsive imports when a relative import exists."""

from pathlib import Path

PACKAGE = "import 'package:lgbtindernew/core/responsive/responsive.dart';\n"
root = Path(__file__).resolve().parents[1] / "lib"

for path in root.rglob("*.dart"):
    text = path.read_text(encoding="utf-8")
    if PACKAGE not in text:
        continue
    if "/responsive/responsive.dart" not in text and "..\\responsive\\responsive.dart" not in text:
        continue
    updated = text.replace(PACKAGE, "", 1)
    if updated != text:
        path.write_text(updated, encoding="utf-8")
        print(path.relative_to(root.parent))
