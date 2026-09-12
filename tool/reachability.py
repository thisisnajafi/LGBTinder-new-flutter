"""Compute which Dart files under lib/ are reachable from lib/main.dart.

Resolves both `package:lgbtindernew/...` and relative import/export/part URIs,
then does a BFS from the entrypoint. Used to prove a file is dead before
deleting it.
"""

import os
import re
import sys
import json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(ROOT, "lib")
PACKAGE = "lgbtindernew"
ENTRY = os.path.join(LIB, "main.dart")

# import/export/part directives, single or double quoted.
DIRECTIVE = re.compile(
    r"""^\s*(?:import|export|part)\s+(?P<q>['"])(?P<uri>[^'"]+)(?P=q)""",
    re.MULTILINE,
)


def all_dart_files():
    out = []
    for dirpath, _dirnames, filenames in os.walk(LIB):
        for fn in filenames:
            if fn.endswith(".dart"):
                out.append(os.path.normpath(os.path.join(dirpath, fn)))
    return out


def resolve(uri, from_file):
    """Map a Dart URI to an absolute path under lib/, or None if external."""
    if uri.startswith("dart:"):
        return None
    if uri.startswith("package:"):
        rest = uri[len("package:"):]
        pkg, _, path = rest.partition("/")
        if pkg != PACKAGE:
            return None
        return os.path.normpath(os.path.join(LIB, path))
    if uri.startswith(("http:", "https:")):
        return None
    # relative
    return os.path.normpath(os.path.join(os.path.dirname(from_file), uri))


def edges(path):
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            src = fh.read()
    except OSError:
        return []
    out = []
    for m in DIRECTIVE.finditer(src):
        target = resolve(m.group("uri"), path)
        if target and target.endswith(".dart"):
            out.append(target)
    return out


def main():
    files = set(all_dart_files())
    if not os.path.exists(ENTRY):
        sys.exit(f"entrypoint missing: {ENTRY}")

    reachable = set()
    queue = [os.path.normpath(ENTRY)]
    while queue:
        cur = queue.pop()
        if cur in reachable or cur not in files:
            continue
        reachable.add(cur)
        queue.extend(edges(cur))

    unreachable = sorted(files - reachable)

    def rel(p):
        return os.path.relpath(p, ROOT).replace("\\", "/")

    print(f"total     : {len(files)}")
    print(f"reachable : {len(reachable)}")
    print(f"unreachable: {len(unreachable)}")

    with open(os.path.join(ROOT, "tool", "unreachable.json"), "w") as fh:
        json.dump([rel(p) for p in unreachable], fh, indent=1)
    with open(os.path.join(ROOT, "tool", "reachable.json"), "w") as fh:
        json.dump(sorted(rel(p) for p in reachable), fh, indent=1)


if __name__ == "__main__":
    main()
