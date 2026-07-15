#!/usr/bin/env python3
"""Check that each examples/*_vars.yaml defines the same top-level keys as
its platform's real vars.yaml.

The examples are copy-paste starting points; when a key is added to a real
config but not the example (or vice versa), the example rots silently. Keys
are read from the raw text so this needs no YAML library.
"""

import re
import sys

PAIRS = [
    ("macOS/vars.yaml", "examples/macOS_vars.yaml"),
    ("ubuntu/vars.yaml", "examples/ubuntu_vars.yaml"),
    ("debian/vars.yaml", "examples/debian_vars.yaml"),
    ("fedora/vars.yaml", "examples/fedora_vars.yaml"),
    ("windows/vars.yaml", "examples/windows_vars.yaml"),
]

TOP_LEVEL_KEY = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")


def top_level_keys(path):
    keys = set()
    with open(path, encoding="utf-8") as handle:
        for line in handle:
            match = TOP_LEVEL_KEY.match(line)
            if match:
                keys.add(match.group(1))
    return keys


def main():
    failures = 0
    for real, example in PAIRS:
        real_keys = top_level_keys(real)
        example_keys = top_level_keys(example)
        missing = real_keys - example_keys
        extra = example_keys - real_keys
        if missing or extra:
            failures += 1
            print(f"DRIFT: {example}")
            for key in sorted(missing):
                print(f"  missing key present in {real}: {key}")
            for key in sorted(extra):
                print(f"  extra key absent from {real}: {key}")
        else:
            print(f"OK: {example}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
