#!/usr/bin/env python3
"""Read-only stdlib SWAPSHOT Godot project structural audit. Not a gameplay test."""
from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

RESOURCE_REF = re.compile(r'''["'](res://[^"'\r\n]+)["']''')
MAIN = re.compile(r'^\s*run/main_scene\s*=\s*["\']([^"\']+)["\']', re.M)
IGNORE = {".git", ".godot", "build", "dist", "exports", "__pycache__", ".venv"}
SOURCE_SUFFIXES = {".gd", ".tscn", ".tres", ".gdshader", ".gdshaderinc"}


def audit(root: Path, release: bool = False) -> dict:
    root = root.resolve()
    found: list[dict] = []
    scanned = 0
    references = 0

    def report(severity, rule, location, detail):
        found.append(dict(severity=severity, rule=rule, location=location, detail=detail))

    project = root / "project.godot"
    if not project.is_file():
        report("BLOCKER", "PROJECT_MISSING", "project.godot", "Missing project.godot")
    else:
        try:
            content = project.read_text(encoding="utf-8-sig")
            match = MAIN.search(content)
            if not match:
                report("MAJOR", "MAIN_SCENE_UNSET", "project.godot", "No run/main_scene found")
            elif match.group(1).startswith("res://") and not (root / match.group(1)[6:]).is_file():
                report("BLOCKER", "MAIN_SCENE_INVALID", "project.godot", match.group(1))
        except (UnicodeError, OSError) as error:
            report("BLOCKER", "PROJECT_UNREADABLE", "project.godot", str(error))

    scenes = 0
    for path in sorted(root.rglob("*")):
        if not path.is_file() or any(part in IGNORE for part in path.relative_to(root).parts):
            continue
        if path.suffix not in SOURCE_SUFFIXES:
            continue
        if path.suffix == ".tscn":
            scenes += 1
        scanned += 1
        try:
            content = path.read_text(encoding="utf-8-sig")
        except (UnicodeError, OSError) as error:
            report("MAJOR", "SOURCE_UNREADABLE", str(path.relative_to(root)), str(error))
            continue
        for line_no, line in enumerate(content.splitlines(), 1):
            if line.lstrip().startswith("#"):
                continue
            for raw in RESOURCE_REF.findall(line):
                references += 1
                relative = raw[6:]
                if any(marker in relative for marker in ("%", "{", "}", "$", "*")):
                    continue
                if not relative or ".." in Path(relative).parts or "\\" in relative or not (root / relative).exists():
                    report("MAJOR", "MISSING_RESOURCE", f"{path.relative_to(root).as_posix()}:{line_no}", raw)

    if not scenes:
        report("MAJOR", "NO_SCENES", "scenes/", "No .tscn scene found")
    if release and not (root / "export_presets.cfg").is_file():
        report("MAJOR", "EXPORT_PRESET_MISSING", "export_presets.cfg", "Release requires Web export preset")
    if release and (root / "export_presets.cfg").is_file():
        preset = (root / "export_presets.cfg").read_text(encoding="utf-8-sig")
        if not re.search(r'^platform\s*=\s*["\']Web["\']', preset, re.M):
            report("MAJOR", "WEB_PRESET_MISSING", "export_presets.cfg", "Release requires a Web preset")

    failed = any(f["severity"] in {"BLOCKER", "MAJOR"} for f in found)
    return dict(root=str(root), release=release, files_scanned=scanned,
                resource_references=references, findings=found, result="FAIL" if failed else "PASS")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path.cwd())
    parser.add_argument("--release", action="store_true")
    parser.add_argument("--format", choices=["json", "markdown"], default="markdown")
    args = parser.parse_args()
    if not args.root.is_dir():
        parser.error(f"Not a directory: {args.root}")
    data = audit(args.root, args.release)
    if args.format == "json":
        print(json.dumps(data, indent=2))
    else:
        print(f"# SWAPSHOT static audit\n\nResult: **{data['result']}**\n")
        print(f"Scanned {data['files_scanned']} Godot source files, {data['resource_references']} references.")
        for f in data["findings"]:
            print(f"- {f['severity']} {f['rule']} at {f['location']}: {f['detail']}")
        print("\nThis is not an engine or gameplay verification.")
    return 2 if data["result"] == "FAIL" else 0


if __name__ == "__main__":
    raise SystemExit(main())
