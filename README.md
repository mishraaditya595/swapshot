# SWAPSHOT

> **Don't take cover. Change the battlefield.**

SWAPSHOT is a single-player, third-person tactical shooter built for **GitHub Game Off 2026** (theme: **SHIFT**). Play as Vex, a covert operative infiltrating the Helix facility. Plant a holographic anchor, SHIFT into a better position, leave an echo behind, and turn firefights into flanking opportunities.

**Status: repository bootstrap.** The Godot project opens to an empty starter scene; movement, combat, enemy AI, SHIFT, and an exported playable build **have not yet been implemented**.

## Scope

- **Engine:** Godot **4.7.2 stable**, GDScript, Compatibility renderer for planned Web export.
- **P0 prototype:** one small arena, third-person movement/aiming, one rifle, one basic enemy, safe SHIFT teleport, damage/HUD, win/retry flow.
- **Intended release:** an 8–12-minute mission through Loading Dock, Security Core, and Extraction (subject to schedule). No multiplayer, open world, inventory, or live services.
- **Target platform:** HTML5 via itch.io; desktop build optional.

## Getting started

1. Install [Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/) (standard/non-.NET).
2. Clone this repository and import `project.godot` through the Godot Project Manager.
3. Open or run `scenes/main.tscn`. The scene is currently a deliberately minimal scaffold, **not a playable demo**.
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

The commands above check source/import integrity; they do **not** prove the gameplay is fun or the Web export works.

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
