"""Classify stub/placeholder Dart files and check them against reachability.

A file is only reported as safe to delete if it matches a stub signature AND is
absent from the reachable set computed by reachability.py.
"""

import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

with open(os.path.join(ROOT, "tool", "reachable.json")) as fh:
    reachable = set(json.load(fh))
with open(os.path.join(ROOT, "tool", "unreachable.json")) as fh:
    unreachable = set(json.load(fh))

SIGNATURES = [
    ("placeholder_screen", re.compile(r"""child:\s*(?:const\s+)?Text\(\s*['"]\w+\s+Screen['"]""")),
    ("todo_widget", re.compile(r"//\s*TODO:\s*Implement widget")),
    ("todo_class", re.compile(r"//\s*TODO:\s*Implement class")),
    ("unimplemented_service", re.compile(r"throw UnimplementedError\(\)")),
]

buckets = {name: {"dead": [], "live": []} for name, _ in SIGNATURES}

for rel in sorted(reachable | unreachable):
    path = os.path.join(ROOT, rel.replace("/", os.sep))
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            src = fh.read()
    except OSError:
        continue
    for name, pat in SIGNATURES:
        if pat.search(src):
            key = "live" if rel in reachable else "dead"
            buckets[name][key].append(rel)
            break

total_dead = 0
for name, groups in buckets.items():
    print(f"\n=== {name} ===")
    print(f"  unreachable (safe to delete): {len(groups['dead'])}")
    print(f"  REACHABLE (do NOT delete)   : {len(groups['live'])}")
    for rel in groups["live"]:
        print(f"      !! LIVE: {rel}")
    total_dead += len(groups["dead"])

print(f"\ntotal safe to delete: {total_dead}")

with open(os.path.join(ROOT, "tool", "stubs_to_delete.json"), "w") as fh:
    json.dump(sorted(sum((g["dead"] for g in buckets.values()), [])), fh, indent=1)
