#!/usr/bin/env python3
"""Fail PR Web exports that do not contain Godot's browser entrypoint assets.

A structural check only. It is NOT a substitute for loading the hosted game.
"""
from __future__ import annotations

import sys
from pathlib import Path


REQUIRED = ("index.html", "index.js", "index.wasm", "index.pck")


def errors_for(directory: Path) -> list[str]:
    problems: list[str] = []
    if not directory.is_dir():
        return [f"Web export directory is missing: {directory}"]
    for name in REQUIRED:
        path = directory / name
        if not path.is_file() or path.is_symlink() or path.stat().st_size == 0:
            problems.append(f"Missing, empty or unsafe Godot export file: {name}")
    if not problems:
        html = (directory / "index.html").read_text(encoding="utf-8")
        if "index.wasm" not in html or "index.pck" not in html:
            problems.append("HTML entrypoint does not refer to its Godot Web resources")
    for path in directory.rglob("*"):
        if path.is_symlink():
            problems.append(f"Symlinks are not allowed in Web preview: {path.name}")
    return problems


def main() -> int:
    if len(sys.argv) != 2:
        print("Usage: python3 verify_web_preview.py <web-export-directory>", file=sys.stderr)
        return 2
    issues = errors_for(Path(sys.argv[1]))
    if issues:
        for issue in issues:
            print(f"WEB PREVIEW FAIL: {issue}", file=sys.stderr)
        return 1
    print("WEB PREVIEW PASS: Godot HTML/JavaScript/WASM/PCK export files present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
