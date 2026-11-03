# SWAPSHOT

> **Don't take cover. Change the battlefield.**

SWAPSHOT is a single-player, third-person tactical shooter built for **GitHub Game Off 2026** (theme: **SHIFT**). Play as Vex, a covert operative infiltrating the Helix facility. Plant a holographic anchor, SHIFT into a better position, leave an echo behind, and turn firefights into flanking opportunities.

**Status: MS-01 Web-first gameplay foundation accepted in PR #4 (merge pending).** The feature branch includes a third-person movement/camera training arena, with manual macOS browser QA recorded in [the MS-01 review](docs/reviews/MS-01-review.md). Rifle combat, enemy AI and SHIFT are planned for later milestones. The playable Web snapshot is published only when the owner manually triggers deployment; a successful preview is not the final game release.

## Scope

- **Engine:** Godot **4.7.2 stable**, GDScript, Compatibility renderer for planned Web export.
- **P0 prototype:** one small arena, third-person movement/aiming, one rifle, one basic enemy, safe SHIFT teleport, damage/HUD, win/retry flow.
- **Intended release:** an 8–12-minute mission through Loading Dock, Security Core, and Extraction (subject to schedule). No multiplayer, open world, inventory, or live services.
- **Target platform:** HTML5 via itch.io; desktop build optional.

## Getting started

1. Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/) (standard/non-.NET).
2. Clone this repository and import `project.godot` through the Godot Project Manager.
3. Run `scenes/main.tscn` to enter the training arena. **WASD** moves, **mouse** looks after clicking the viewport, and **Esc** releases the cursor. Traverse the ramp to reach the elevated platform; jump/combat/SHIFT are reserved for later milestones.
4. Run the static review audit and tests:

```bash
python3 .agents/skills/swapshot-review/scripts/audit_project.py --root .
python3 -m unittest discover -s .agents/skills/swapshot-review/tests -v
```

If Godot is installed, also run:

```bash
godot --headless --path . --import
godot --headless --path . --quit-after 2
```

For the MS-01 branch, also run `godot --headless --path . --script res://tests/ms01_scene_smoke.gd`. The project owner opted for manual **browser-first** gameplay QA instead of a local editor session; the completed macOS browser acceptance record and the corrected camera regression are in [the review report](docs/reviews/MS-01-review.md). Headless tests alone do not prove camera comfort. The final public Web release still requires separate browser testing.

## Manual browser deployment

The [GitHub Pages deployment workflow](https://github.com/mishraaditya595/swapshot/actions/workflows/deploy-web-manual.yml)
runs **only** when the owner chooses **Run workflow**. PR opens, updates and
merges do not publish or refresh the game. For a PR #N, choose source `pr`
and enter its number; the preview lives at `/swapshot/pr-N/`. For the latest
merged `main`, choose source `main` with no PR number; it publishes to
`/swapshot/play/`. A playable PR #4 snapshot was manually deployed and
tested on November 3, 2026. See [the acceptance record](docs/reviews/MS-01-review.md)
for actual results and limitations.

## Browser PR previews

Web deployment is **manual only**. Opening, updating, or merging a PR does
not deploy anything. After the [manual Pages deployment infrastructure](docs/PR_WEB_PREVIEWS.md)
is merged and GitHub Pages is enabled, choose **Actions → SWAPSHOT Deploy Web
to GitHub Pages (Manual) → Run workflow** to publish a specific open PR
(`/swapshot/pr-N/`) or the latest merged `main` (`/swapshot/play/`).
The [preview hub](https://mishraaditya595.github.io/swapshot/) lists
previously deployed snapshots. Browser QA is still required before a gameplay
milestone can be accepted.

## Development milestones

**[View the full milestone/PR checklist](docs/MILESTONES.md)** — the single source of truth from the first gameplay GDScript to release. Each milestone is its own PR. Coding agents must tick its verified tasks, check off the completed milestone and record the **actual PR number/link in the same file** before asking to merge. Milestone MS-00 (repository bootstrap) is already completed by [PR #1](https://github.com/mishraaditya595/swapshot/pull/1); gameplay milestones remain pending.

## Pull request quality checks

[Pre-merge quality gate](docs/PRE_MERGE.md) documents the PR acceptance checks, conservative static code review, Godot/CI tests, and how to make job names mandatory under the GitHub `main` ruleset. Automated checks do **not** substitute for in-editor playtesting or human review.

## Architecture and collaboration

- [Agent instructions](AGENTS.md) and [Claude instructions](CLAUDE.md)
- [Canonical game design and scope](docs/GAME_DESIGN.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [Agent workflow and verification rules](docs/AGENT_WORKFLOW.md)
- [Third-party skill sources and licenses](docs/SKILLS.md)
- [Original interactive design brief](.agents/skills/swapshot-review/references/source-design-brief.html)

Agent skills are vendored in `.agents/skills/`: `brainstorming`, `find-skills`, `verification-before-completion`, and the project-specific `swapshot-review`. Claude Code uses wrapper entry points in `.claude/skills/`. See [SKILLS.md](docs/SKILLS.md).

## Contributing

Work in small branches and reviewable PRs; do not push unreviewed game features directly to `main`. Include the behavior, test evidence, risks, and manual playtest steps in each PR. Follow `AGENTS.md` and the PR template. Respect licenses and attribute external assets. Do not add large binary art or export artifacts to Git without a deliberate asset-management decision.

## License / credits

A game license for SWAPSHOT itself is **not selected yet**; do not assume source/assets are freely reusable. Bundled third-party agent skills retain their upstream MIT notices in `.agents/skills/_licenses/`. Game content/asset licenses and the final AI-assisted-development disclosure will be documented before release.
