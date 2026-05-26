import os
import re
from pathlib import Path

LIB = Path(__file__).resolve().parent.parent / "lib"
SCAFFOLD = LIB / "core" / "widgets" / "app_page_scaffold.dart"
HEADER = LIB / "core" / "widgets" / "app_page_header.dart"


def rel_import(from_file: Path, target: Path) -> str:
    return Path(os.path.relpath(target, from_file.parent)).as_posix()


simple_pattern = re.compile(
    r"return Scaffold\(\s*"
    r"backgroundColor:\s*(?P<bg>[^,]+),\s*"
    r"appBar:\s*AppBarCustom\(\s*"
    r"title:\s*(?P<title>(?:'[^']*'|\"[^\"]*\")),\s*"
    r"showBackButton:\s*true,?\s*"
    r"\),\s*"
    r"body:\s*",
    re.MULTILINE,
)

loading_pattern = re.compile(
    r"return Scaffold\(\s*"
    r"backgroundColor:\s*(?P<bg>[^,]+),\s*"
    r"appBar:\s*AppBarCustom\(\s*"
    r"title:\s*(?P<title>(?:'[^']*'|\"[^\"]*\")),\s*"
    r"showBackButton:\s*true,?\s*"
    r"\),\s*"
    r"body:\s*(?P<body>const Center\(child: CircularProgressIndicator\(\)\),?\s*)\);",
    re.MULTILINE,
)

import_line = re.compile(r"import\s+'[^']*/widgets/navbar/app_bar_custom\.dart';\n")


def repl_simple(m: re.Match) -> str:
    return (
        f"return AppPageScaffold(\n"
        f"      title: {m.group('title')},\n"
        f"      showBackButton: true,\n"
        f"      backgroundColor: {m.group('bg')},\n"
        f"      body: "
    )


def repl_loading(m: re.Match) -> str:
    return (
        f"return AppPageScaffold(\n"
        f"      title: {m.group('title')},\n"
        f"      showBackButton: true,\n"
        f"      backgroundColor: {m.group('bg')},\n"
        f"      body: {m.group('body')});\n"
    )


migrated = []
skipped = []

for path in sorted(LIB.rglob("*.dart")):
    if path.name == "app_bar_custom.dart":
        continue
    text = path.read_text(encoding="utf-8")
    if "AppBarCustom" not in text:
        continue

    orig = text
    scaffold_imp = rel_import(path, SCAFFOLD)
    header_imp = rel_import(path, HEADER)

    if import_line.search(text):
        text = import_line.sub(
            f"import '{scaffold_imp}';\nimport '{header_imp}';\n",
            text,
            count=1,
        )

    text, n1 = loading_pattern.subn(repl_loading, text)
    text, n2 = simple_pattern.subn(repl_simple, text)

    if text != orig:
        path.write_text(text, encoding="utf-8")
        migrated.append((str(path.relative_to(LIB.parent)), n1 + n2))
    else:
        skipped.append(str(path.relative_to(LIB.parent)))

print(f"Migrated {len(migrated)} files")
for p, c in migrated:
    print(f"  {p} ({c})")
print(f"Skipped {len(skipped)} files:")
for p in skipped:
    print(f"  {p}")
