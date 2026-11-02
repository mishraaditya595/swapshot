#!/usr/bin/env python3
"""Render a static index of existing hosted per-PR Godot snapshots.

The trusted deployment workflow runs this script from the default branch;
it never executes downloaded PR artifacts.
"""
from __future__ import annotations

import argparse
import html
import re
from pathlib import Path

PR_DIRECTORY = re.compile(r"pr-(\d+)")


def collect_previews(site: Path) -> list[int]:
    found: list[int] = []
    for child in site.iterdir():
        match = PR_DIRECTORY.fullmatch(child.name)
        if match and child.is_dir() and (child / "index.html").is_file():
            found.append(int(match.group(1)))
    return sorted(set(found), reverse=True)


def render(previews: list[int]) -> str:
    tiles = "".join(
        f'<li><a href="pr-{num}/">Play PR #{num}</a>'
        f' <span>·</span> <a class="source" '
        f'href="https://github.com/mishraaditya595/swapshot/pull/{num}">'
        f'View code and tests</a></li>\n'
        for num in previews
    )
    if not tiles:
        tiles = "<li>No preview builds have been published yet.</li>"
    return """<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SWAPSHOT · Playtest builds</title>
<style>
:root { color-scheme: dark; }
body { max-width: 48rem; margin: 4rem auto; padding: 0 1.5rem;
background: #121923; color: #e2edf2; font: 1.05rem/1.6 system-ui, sans-serif; }
h1 { font-size: clamp(2rem, 5vw, 3rem); }
a { color: #67ddd5; }
li { padding: .85rem 0; border-bottom: 1px solid #33404c; }
.source { font-size: .88rem; color: #b0c6d5; }
.note { color: #b0c6d5; font-size: .92rem; }
</style></head><body>
<p class="note">GITHUB GAME OFF 2026 · DEVELOPMENT PREVIEWS</p>
<h1>SWAPSHOT</h1>
<p>Browser builds of individual pull requests. These are works in progress,
not a release or proof of completed manual gameplay QA.</p>
<ul>""" + tiles + """</ul>
<p class="note">Desktop keyboard and mouse recommended.
Requires a browser with WebAssembly and WebGL 2.0.</p>
</body></html>
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("site", type=Path)
    args = parser.parse_args()
    if not args.site.is_dir():
        parser.error("Site root must be an existing directory")
    previews = collect_previews(args.site)
    (args.site / "index.html").write_text(render(previews), encoding="utf-8")
    print(f"Rendered preview index with {len(previews)} PR(s).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
