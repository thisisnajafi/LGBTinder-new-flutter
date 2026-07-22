#!/usr/bin/env python3
"""Ensure every file using AppText imports responsive.dart."""

from pathlib import Path

root = Path(__file__).resolve().parents[1] / "lib"
responsive = root / "core" / "responsive" / "responsive.dart"


def import_line(path: Path) -> str:
    rel = Path(
        os_path_relative(path.parent, responsive.parent)
    ).joinpath("responsive.dart")
    return f"import '{rel.as_posix()}';\n"


def os_path_relative(src: Path, dst: Path) -> str:
    import os

    return os.path.relpath(dst, src).replace("\\", "/")


for path in sorted(root.rglob("*.dart")):
    if path.name == "responsive_text.dart":
        continue
    text = path.read_text(encoding="utf-8")
    if "AppText(" not in text:
        continue
    if "responsive/responsive.dart" in text:
        continue

    imp = import_line(path)
    lines = text.splitlines(keepends=True)
    last_import = 0
    for idx, line in enumerate(lines):
        if line.startswith("import "):
            last_import = idx + 1
    lines.insert(last_import, imp)
    path.write_text("".join(lines), encoding="utf-8")
    print(path.relative_to(root.parent))
