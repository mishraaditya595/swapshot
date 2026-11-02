#!/usr/bin/env python3
"""Validate SWAPSHOT's single-source milestone tracker (structure, not gameplay)."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

HEADING = re.compile(r"^### MS-(\d{2}) — .+$")
CHECK = re.compile(r"^- \[([ x])\] \*\*MS-(\d{2}) complete\*\* — \*\*Implementing PR:\*\* (.+)$")
TASK = re.compile(r"^  - \[([ x])\] .+$")
PR = re.compile(r"^\[#(\d+)\]\(https://github\.com/mishraaditya595/swapshot/pull/(\d+)\)$")
EXPECTED_IDS = list(range(17))


def validate(content: str) -> list[str]:
    lines = content.splitlines()
    found = [(index, int(match.group(1))) for index, line in enumerate(lines)
             if (match := HEADING.fullmatch(line))]
    errors: list[str] = []
    ids = [milestone for _, milestone in found]
    if ids != EXPECTED_IDS:
        errors.append(f"Expected ordered IDs MS-00 through MS-16; got {ids!r}")
    seen_prs: dict[int, int] = {}
    for position, (index, number) in enumerate(found):
        end = found[position + 1][0] if position + 1 < len(found) else len(lines)
        block = lines[index + 1:end]
        checks = [match for line in block if (match := CHECK.fullmatch(line))]
        tasks = [match.group(1) for line in block if (match := TASK.fullmatch(line))]
        label = f"MS-{number:02}"
        if len(checks) != 1:
            errors.append(f"{label}: expected exactly one completion checkbox, found {len(checks)}")
            continue
        if int(checks[0].group(2)) != number:
            errors.append(f"{label}: completion label must match heading")
        if len(tasks) < 3:
            errors.append(f"{label}: expected at least three indented task checkboxes")
        complete = checks[0].group(1) == "x"
        pr_text = checks[0].group(3).strip()
        link = PR.fullmatch(pr_text)
        if complete:
            if not tasks or any(flag != "x" for flag in tasks):
                errors.append(f"{label}: checked milestone still has unchecked tasks")
            if not link or link.group(1) != link.group(2):
                errors.append(f"{label}: completed milestone requires a matching GitHub PR link")
            else:
                pr = int(link.group(1))
                if pr in seen_prs:
                    errors.append(f"{label}: PR #{pr} already assigned to MS-{seen_prs[pr]:02}")
                seen_prs[pr] = number
        elif pr_text != "—" and (not link or link.group(1) != link.group(2)):
            errors.append(f"{label}: pending PR must be — or a valid in-progress PR link")
    if not found:
        errors.append("No milestone headings were found")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("path", nargs="?", type=Path, default=Path("docs/MILESTONES.md"))
    args = parser.parse_args()
    if not args.path.is_file():
        print(f"ERROR: milestone tracker is missing: {args.path}")
        return 2
    errors = validate(args.path.read_text(encoding="utf-8"))
    if errors:
        print("MILESTONE TRACKER FAILED:")
        for error in errors:
            print(f"- {error}")
        return 1
    print("MILESTONE TRACKER PASS: MS-00 to MS-16, valid completion states and PR links")
    print("Structural checks only; implementation and verification evidence require human review.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
