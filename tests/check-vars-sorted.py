#!/usr/bin/env python3
"""Check that list entries in vars.yaml files are alphabetically sorted.

The editing guideline in CLAUDE.md says package entries stay alphabetically
sorted within their group. Comment groups are invisible to a YAML parser, so
this works on the raw text: any comment or blank line ends the current group,
and entries between boundaries must be sorted case-insensitively.

Entries are top-level list items (two-space indent): either plain strings
(macOS style) or objects whose first line is `- name: ...`. Deeper-indented
lines belong to the current entry and are ignored.

custom_commands lists are excluded because their order is execution order.
"""

import re
import sys

EXCLUDED_KEYS = {
    "custom_commands",
    "custom_commands_user",
    "custom_commands_elevated",
}

TOP_LEVEL_KEY = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")
ENTRY = re.compile(r"^  - (?:name:\s*)?(.+?)\s*$")


def check_file(path):
    errors = []
    key = None
    prev = None  # (lineno, value) of previous entry in the current group

    with open(path, encoding="utf-8") as handle:
        for lineno, raw in enumerate(handle, 1):
            line = raw.rstrip("\n")

            match = TOP_LEVEL_KEY.match(line)
            if match:
                key = match.group(1)
                prev = None
                continue

            if key is None or key in EXCLUDED_KEYS:
                continue

            # Comments and blank lines end the current group.
            if not line.strip() or line.lstrip().startswith("#"):
                prev = None
                continue

            match = ENTRY.match(line)
            if not match:
                continue

            value = match.group(1).split(" #")[0].strip().strip("\"'")
            if prev is not None and prev[1].lower() > value.lower():
                errors.append(
                    f"{path}:{lineno}: '{value}' should come before "
                    f"'{prev[1]}' (line {prev[0]}) in {key}"
                )
            prev = (lineno, value)

    return errors


def main(paths):
    all_errors = []
    for path in paths:
        all_errors.extend(check_file(path))
    for error in all_errors:
        print(error)
    if all_errors:
        print(f"\n{len(all_errors)} sort violation(s) found")
        return 1
    print(f"All {len(paths)} file(s) sorted")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: check-vars-sorted.py <vars.yaml> [...]", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1:]))
