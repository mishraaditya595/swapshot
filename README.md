# SWAPSHOT

> **Don't take cover. Change the battlefield.**

**[Play SWAPSHOT online — GitHub Pages](https://mishraaditya595.github.io/swapshot/)**

The preview hub links to browser builds published manually by the repository owner. Opening or merging a PR does not deploy a new build.

SWAPSHOT is a single-player third-person shooter for **GitHub Game Off 2026**, whose theme is **SHIFT**. You play Vex, an operative infiltrating the Helix research facility. Place a holographic anchor, teleport to a better firing position, and leave an echo behind to distract enemies.

## Scope

- **Engine:** Godot **4.7.2 stable**, GDScript, Compatibility renderer for planned Web export.
- **P0 prototype:** one small arena, third-person movement/aiming, one rifle, one basic enemy, safe SHIFT teleport, damage/HUD, win/retry flow.
- **Intended release:** an 8–12-minute mission through Loading Dock, Security Core, and Extraction (subject to schedule). No multiplayer, open world, inventory, or live services.
- **Target platform:** HTML5 via itch.io; desktop build optional.

## Getting started

1. Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/) (standard/non-.NET).
2. Clone this repository and import `project.godot` through the Godot Project Manager.
3. Run `scenes/main.tscn` for the MS-09 Security Core preview. Clear two lower guards, climb either ramp to the elevated catwalk, defeat two upper guards, then approach the unlocked west terminal and press E to shut it down. The result panel offers a full section replay. The MS-08 Loading Dock remains directly playable at `scenes/levels/loading_dock.tscn`. WASD moves, mouse looks after capturing the viewport, left mouse fires, right mouse aims, R reloads, Q places an anchor, Left Shift teleports, E interacts and Esc releases the cursor. The initial click captures the mouse without shooting. The original P0 firefight remains at `scenes/levels/ms06_firefight.tscn`, and the training arena at `scenes/levels/greybox_arena.tscn`. MS-09's Godot smoke test runs from `tests/ms09_security_core_smoke.gd`.
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

MS-08 still requires a first-time hosted browser playtest before acceptance; its pending checks remain in [issue #19](https://github.com/mishraaditya595/swapshot/issues/19). MS-09 also requires hosted camera, SHIFT, combat and terminal playtesting before acceptance. See [the MS-09 worksheet](tests/MS-09-BROWSER-QA.md) and [review](docs/reviews/MS-09-review.md).

To check gameplay regressions, run `godot --headless --path . --script res://tests/ms01_scene_smoke.gd` and `godot --headless --path . --script res://tests/ms02_rifle_smoke.gd`. For SHIFT safety, run `godot --headless --path . --script res://tests/ms03_shift_smoke.gd`. For lifecycle tests, run `godot --headless --path . --script res://tests/ms04_shift_lifecycle_smoke.gd`. For enemy combat, run `godot --headless --path . --script res://tests/ms05_enemy_smoke.gd`. For the complete encounter, MS-07 safety and Loading Dock regressions, run `tests/ms06_loop_smoke.gd`, `tests/ms07_p0_review_smoke.gd` and `tests/ms08_loading_dock_smoke.gd` with the same Godot command. The [MS-01 review report](docs/reviews/MS-01-review.md) records the owner's macOS browser playtest and a corrected camera regression. The camera fully hides the player silhouette when forced close to a wall or crate, without changing rifle aiming. The MS-05 arena acknowledges the objective after the trooper is defeated. The project uses manual **browser-first** gameplay QA instead of a local editor session. Headless tests cannot establish whether the camera feels comfortable, and the final public Web release still needs its own browser test.

## Manual browser deployment

The [GitHub Pages deployment workflow](https://github.com/mishraaditya595/swapshot/actions/workflows/deploy-web-manual.yml) runs only when the owner selects **Run workflow**. To publish an open PR, choose source `pr` and enter its number. The build appears at `/swapshot/pr-N/`. To publish the latest merged `main`, choose source `main` and leave the PR number blank; that build appears at `/swapshot/play/`.

A PR #4 snapshot was manually deployed and tested on November 3, 2026. The [MS-01 acceptance record](docs/reviews/MS-01-review.md) has the results and limitations. The [preview hub](https://mishraaditya595.github.io/swapshot/) lists published snapshots. Follow the [deployment guide](docs/PR_WEB_PREVIEWS.md) for setup, security boundaries, and troubleshooting. A deployed build still needs hands-on browser QA before a gameplay milestone is accepted.

## Development milestones

The [milestone and PR checklist](docs/MILESTONES.md) tracks work from the first gameplay GDScript to release. Each milestone has its own PR. Agents must mark tasks complete only after verification, then add the real PR number and link to the same file before requesting a merge. Bootstrap milestone MS-00 was completed in [PR #1](https://github.com/mishraaditya595/swapshot/pull/1). Check the tracker for current gameplay status.

## Pull request quality checks

The [pre-merge guide](docs/PRE_MERGE.md) explains PR acceptance checks, static review, Godot CI, and required checks for the GitHub `main` ruleset. Gameplay still needs human review and playtesting.

## Architecture and collaboration

- [Agent instructions](AGENTS.md) and [Claude instructions](CLAUDE.md)
- [Canonical game design and scope](docs/GAME_DESIGN.md)
- [Technical architecture](docs/ARCHITECTURE.md)
- [Agent workflow and verification rules](docs/AGENT_WORKFLOW.md)
- [Third-party skill sources and licenses](docs/SKILLS.md)
- [Original interactive design brief](.agents/skills/swapshot-review/references/source-design-brief.html)

The repository includes local agent skills in `.agents/skills/`, with Claude Code entry points in `.claude/skills/`. Agents must apply [Humanizer](.agents/skills/humanizer/SKILL.md) to reader-facing prose before committing or sharing it, without changing technical facts, commands, links, or controls. This is an agent instruction; CI does not enforce it. The full list and licenses are in [SKILLS.md](docs/SKILLS.md).

## Contributing

Use a separate branch for each focused change and open a PR before merging into `main`. Describe what changed, the tests you ran, remaining risks, and manual playtest steps. Follow `AGENTS.md` and the PR template. Credit external assets and check their licenses. Large binary art and exported builds need an explicit asset-management decision before being committed.

## License / credits

SWAPSHOT does not yet have a game license, so do not assume its code or assets can be reused. Third-party agent skill licenses are kept in `.agents/skills/_licenses/`. The game content licenses, asset credits, and final AI-assistance disclosure are due before release.
