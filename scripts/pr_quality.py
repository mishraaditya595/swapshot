#!/usr/bin/env python3
"""SWAPSHOT PR policy and conservative static review; not an AI or gameplay review.

Runs in unprivileged pull_request CI with no secrets and no write token.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path

from validate_milestones import CHECK, HEADING, TASK, validate as validate_tracker

REPO_URL = "https://github.com/mishraaditya595/swapshot/pull/"
MILESTONE_FIELD = re.compile(r"(?im)^\s*(?:[-*]\s*)?\*\*Milestone:\*\*\s*(MS-\d{2})\s*$")
GOVERNANCE_FIELD = re.compile(r"(?im)^\s*(?:[-*]\s*)?\*\*Change type:\*\*\s*governance\s*$")
POC_DEFER_FIELD = re.compile(
    r"(?im)^\s*\*\*POC deferral:\*\*\s*(#[0-9]+(?:\s*,\s*#[0-9]+)*)\s*$"
)
# Owner-approved, PR-specific POC exception. This is not milestone completion.
# Remove it after the deferred acceptance checklists are resolved.
POC_DEFERRALS = {(20, 9): (19, 21)}

SECRET = re.compile(
    r"(?:github_pat_[A-Za-z0-9_]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|"
    r"sk-[A-Za-z0-9_-]{24,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)"
)
EXEC = re.compile(r"\b(?:OS\.execute|JavaScriptBridge\.eval|Expression\.execute)\s*\(")
BLOCKED_SUFFIXES = {".pck", ".wasm", ".p12", ".pfx", ".pem", ".key"}
GAME_SUFFIXES = {".gd", ".tscn", ".tres", ".gdshader", ".glb", ".gltf", ".ogg", ".wav", ".png", ".jpg", ".webp"}
SECTION_TITLES = ("Acceptance evidence", "Verification evidence", "Review findings")


def git(*args: str) -> str:
    outcome = subprocess.run(["git", *args], capture_output=True, text=True, check=True)
    return outcome.stdout


def changed_paths(base: str) -> list[str]:
    return [p for p in git("diff", "--name-only", "--diff-filter=ACMRT", f"{base}...HEAD").splitlines() if p]


def milestone_states(content: str) -> dict[int, tuple[bool, tuple[str, ...], str]]:
    lines = content.splitlines()
    headings = [(i, int(m.group(1))) for i, line in enumerate(lines) if (m := HEADING.fullmatch(line))]
    states = {}
    for j, (start, number) in enumerate(headings):
        end = headings[j + 1][0] if j + 1 < len(headings) else len(lines)
        chunk = lines[start + 1:end]
        headers = [m for line in chunk if (m := CHECK.fullmatch(line))]
        tasks = tuple(m.group(1) for line in chunk if (m := TASK.fullmatch(line)))
        if len(headers) == 1:
            states[number] = (headers[0].group(1) == "x", tasks, headers[0].group(3).strip())
    return states


def section_body(body: str, heading: str) -> str:
    match = re.search(
        r"(?im)^##\s+" + re.escape(heading) + r"\s*$([\s\S]*?)(?=^##\s+|\Z)", body
    )
    if not match:
        return ""
    content = re.sub(r"(?s)<!--.*?-->", "", match.group(1))
    content = re.sub(r"(?m)^\s*[-*]\s*\[[ x]\]\s*", "", content)
    return content.strip()


def substantive(text: str) -> bool:
    compact = text.strip().lower()
    return len(compact) >= 25 and compact not in {"not run", "n/a", "none", "todo", "tbd"}


def governance_path(path: str) -> bool:
    if path in {"README.md", "AGENTS.md", "CLAUDE.md", ".editorconfig", ".gitattributes", ".gitignore"}:
        return True
    if path.endswith((".gd", ".tscn", ".tres", ".gdshader")) or path == "project.godot":
        return False
    if path.startswith(("docs/", ".github/", ".agents/skills/", ".claude/skills/")):
        return True
    return (path.startswith(("scripts/", "tests/")) and path.endswith((".py", ".md", ".sh")))


def policy(event: dict, paths: list[str], before: str, after: str) -> tuple[list[str], list[str]]:
    failures, notes = [], []
    pr = event.get("pull_request", {})
    number = pr.get("number") or event.get("number")
    title = pr.get("title", "")
    body = pr.get("body") or ""
    base_ref = (pr.get("base") or {}).get("ref")
    if base_ref != "main":
        failures.append("PR must target main.")
    if not isinstance(number, int) or number < 1:
        failures.append("PR event must contain a real PR number.")
    if "docs/MILESTONES.md" not in paths and not GOVERNANCE_FIELD.search(body):
        failures.append("Milestone PR must change docs/MILESTONES.md; governance PR must declare its change type.")

    before_errors, after_errors = validate_tracker(before), validate_tracker(after)
    if before_errors:
        failures.append("Base milestone tracker invalid: " + "; ".join(before_errors))
    if after_errors:
        failures.append("Proposed milestone tracker invalid: " + "; ".join(after_errors))
    baseline, proposed = milestone_states(before), milestone_states(after)
    fields = MILESTONE_FIELD.findall(body)
    governance = bool(GOVERNANCE_FIELD.search(body))
    title_ids = re.findall(r"\bMS-\d{2}\b", title)

    poc_fields = POC_DEFER_FIELD.findall(body)
    poc_authorized = False
    if len(poc_fields) > 1:
        failures.append("Exactly one POC deferral field is permitted.")
    if poc_fields:
        identity = int(fields[0][-2:]) if len(fields) == 1 else -1
        issue_numbers = tuple(int(item.strip()[1:]) for item in poc_fields[0].split(","))
        poc_authorized = (
            not governance and len(poc_fields) == 1
            and POC_DEFERRALS.get((number, identity)) == issue_numbers
        )
        if not poc_authorized:
            failures.append("POC deferral is not approved for this PR, milestone and issue list.")

    if governance:
        if fields or title_ids:
            failures.append("Governance PR cannot declare a gameplay milestone.")
        forbidden = [p for p in paths if not governance_path(p)]
        if forbidden:
            failures.append("Governance PR contains implementation files: " + ", ".join(forbidden))
        if not re.match(r"(?i)^(?:ci|docs|chore)(?:\([-\w]+\))?:", title):
            failures.append("Governance PR title must start with ci:, docs: or chore:.")
        for key in set(baseline) | set(proposed):
            a, b = baseline.get(key), proposed.get(key)
            if a is None or b is None or a[0] != b[0] or (a[0] and a != b):
                failures.append(f"Governance PR must preserve existing completion status/history for MS-{key:02}.")
        notes.append("Governance-only change: no gameplay milestone may be marked complete.")
    else:
        if len(fields) != 1 or len(title_ids) != 1 or fields[0] != title_ids[0]:
            failures.append("Exactly one matching MS-XX ID must appear in the PR title and **Milestone:** field.")
        if len(fields) == 1:
            milestone = int(fields[0][-2:])
            if milestone not in range(1, 17):
                failures.append("Implementing milestone must be MS-01 through MS-16.")
            old, new = baseline.get(milestone), proposed.get(milestone)
            if old is None or new is None:
                failures.append("Missing milestone section in the tracker.")
            else:
                if old[0]:
                    failures.append("This milestone is already completed on main.")
                if not new[0] or not new[1] or any(flag != "x" for flag in new[1]):
                    if poc_authorized:
                        notes.append(
                            "POC deferral only: PR #20 may advance with MS-09 unchecked. "
                            "The required manual work remains open in issues #19 and #21; "
                            "this is not final milestone or release acceptance."
                        )
                    else:
                        failures.append("Selected milestone and every task must be checked before merge.")
                expected = f"[#{number}]({REPO_URL}{number})"
                if new[2] != expected:
                    failures.append(f"Selected milestone must link its actual implementing PR: {expected}")
            for key in sorted(set(baseline) | set(proposed)):
                if key == milestone:
                    continue
                if baseline.get(key) != proposed.get(key):
                    failures.append(f"PR cannot change the completion state or checked tasks of MS-{key:02}.")
                if key < milestone and baseline.get(key) and not baseline[key][0]:
                    if not poc_authorized:
                        failures.append(f"Complete prerequisite MS-{key:02} before MS-{milestone:02}.")
            notes.append(f"One milestone PR: MS-{milestone:02}. Human acceptance evidence remains necessary.")
            if poc_authorized:
                notes.append("Outstanding predecessor acceptance remains deferred; release checks still apply.")
        for heading in SECTION_TITLES:
            content = section_body(body, heading)
            if not substantive(content):
                failures.append(f"Add a substantive '## {heading}' section to the PR body.")
        if "docs/MILESTONES.md" not in paths:
            failures.append("Milestone implementation PR must modify docs/MILESTONES.md.")

    return list(dict.fromkeys(failures)), notes


def static_review(paths: list[str], diff_text: str, root: Path) -> tuple[list[str], list[str]]:
    failures, advisories = [], []
    for name in paths:
        path = Path(name)
        pieces = path.parts
        if any(part in {".godot", ".import", "__pycache__", ".venv"} for part in pieces):
            failures.append(f"Generated/editor cache file committed: {name}")
        if pieces and pieces[0] in {"dist", "build", "exports"}:
            failures.append(f"Build artifact committed: {name}")
        if (path.name == ".env" or path.name.startswith(".env.")
                or path.suffix.lower() in BLOCKED_SUFFIXES):
            failures.append(f"Potential credential or exported binary file: {name}")
        target = root / name
        if target.is_file() and target.stat().st_size > 10 * 1024 * 1024:
            failures.append(f"File exceeds 10 MiB; discuss external asset storage: {name}")
    current = ""
    for line in diff_text.splitlines():
        if line.startswith("diff --git "):
            current = line.partition(" b/")[2].strip().strip('"')
        if not line.startswith("+") or line.startswith("+++"):
            continue
        text = line[1:]
        if SECRET.search(text):
            failures.append(f"Possible credential/private key in added code near {current}; value omitted.")
        if current.endswith(".gd") and EXEC.search(text):
            failures.append(f"Unreviewed execution/evaluation API in {current}; replace or justify in reviewed design.")
    if any(p.endswith((".gd", ".tscn", ".tres")) for p in paths):
        advisories.append("Manual Godot gameplay review required: input, collisions, regressions and state cleanup are NOT verified by this script.")
    if any(re.search(r"(shift|anchor|teleport|echo)", p, re.I) for p in paths):
        advisories.append("SHIFT review: verify deployment range, line of sight, capsule clearance at deploy AND activation, cooldown, race cases and echo expiration.")
    if any(re.search(r"(weapon|rifle|bullet|shoot|combat)", p, re.I) for p in paths):
        advisories.append("Combat review: manually verify camera-to-muzzle obstruction, hit detection, recoil, reload and shots through cover.")
    if any(p.startswith(".github/workflows/") for p in paths):
        advisories.append("Workflow review: check token permissions, event trust boundaries, dependency pinning and privileged jobs.")
    if any(p.startswith("assets/") for p in paths):
        advisories.append("Asset review: confirm license/provenance, attribution, load size and browser-friendly import.")
    if not advisories:
        advisories.append("No recognized game-specific risk path changed; still inspect the PR diff manually.")
    advisories.append("Static checks cannot certify code quality, P0/P1 gameplay safety, performance, or external submission.")
    return list(dict.fromkeys(failures)), advisories


def write_report(mode: str, failures: list[str], notes: list[str], report: str | None) -> None:
    outcome = "FAIL" if failures else "PASS (automated checks only)"
    lines = [f"## SWAPSHOT {mode} — {outcome}", ""]
    if failures:
        lines.extend(["### Blocking findings", *[f"- {f}" for f in failures], ""])
    lines.extend(["### Review notes", *[f"- {n}" for n in notes], "",
                  "A passing automated check is **not** approval of gameplay or a substitute for human review."])
    content = "\n".join(lines) + "\n"
    print(content)
    if report:
        Path(report).write_text(content, encoding="utf-8")
    summary = os.getenv("GITHUB_STEP_SUMMARY")
    if summary:
        with open(summary, "a", encoding="utf-8") as fh:
            fh.write(content)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["policy", "review"])
    parser.add_argument("--event", type=Path, required=True)
    parser.add_argument("--report", default=None)
    args = parser.parse_args()
    try:
        event = json.loads(args.event.read_text(encoding="utf-8"))
        base = event["pull_request"]["base"]["sha"]
        paths = changed_paths(base)
        if args.mode == "policy":
            before = git("show", f"{base}:docs/MILESTONES.md")
            after = Path("docs/MILESTONES.md").read_text(encoding="utf-8")
            errors, notes = policy(event, paths, before, after)
        else:
            diff = git("diff", "--no-ext-diff", "--unified=0", f"{base}...HEAD")
            errors, notes = static_review(paths, diff, Path.cwd())
        write_report(args.mode, errors, notes, args.report)
        return 1 if errors else 0
    except (KeyError, ValueError, OSError, subprocess.CalledProcessError) as exc:
        write_report(args.mode, [f"Review could not complete: {type(exc).__name__}: {exc}"], [], args.report)
        return 2


if __name__ == "__main__":
    sys.exit(main())
