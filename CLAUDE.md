# Claude Code — SWAPSHOT

**Read [AGENTS.md](AGENTS.md) first.** It is the canonical, agent-neutral project policy. This file tells Claude Code where to find the installed skills and how to use them, without weakening any requirement in AGENTS.md.

## On every task

1. Read `README.md` and the appropriate sections of `docs/GAME_DESIGN.md` and `docs/ARCHITECTURE.md`.
2. For new features or gameplay behavior, invoke [brainstorming](.agents/skills/brainstorming/SKILL.md) **before implementation**; if design approval is required, get it before scaffolding or modifying code.
3. If a task needs a new specialist skill, consult [find-skills](.agents/skills/find-skills/SKILL.md). Do not install or run third-party code without review/approval.
4. Before saying "done", "fixed", "passes", or "ready", apply [verification-before-completion](.agents/skills/verification-before-completion/SKILL.md) and present command output evidence.
5. Before finalizing a feature PR or release review, apply [swapshot-review](.agents/skills/swapshot-review/SKILL.md) to identify P0/P1 gameplay regressions and unverified manual tests.

These four skills also have lightweight discoverable wrappers under `.claude/skills/`. For the **full original workflow** and references, always read the corresponding canonical `.agents/skills/<name>/SKILL.md` linked above. The wrappers are intentionally not duplicated copies.

## Mandatory milestone workflow

Before working on any game feature, read **[docs/MILESTONES.md](docs/MILESTONES.md)**. Pick the earliest unfinished MS-XX milestone, use one PR for it, and update the SAME file in that PR. Tick individual tasks only after actual verification; tick the milestone only once all tasks and the acceptance gate pass, then link the real implementing PR number. Create the PR first to obtain its number and commit the checklist update afterward. Never infer a passing manual playtest, browser build, or jam submission from a code change. Validate with `python3 scripts/validate_milestones.py docs/MILESTONES.md`. See the complete policy in AGENTS.md.

## Non-negotiables

- **Engine:** Godot **4.7.2 stable** + GDScript; Web-first Compatibility renderer.
- **P0:** one greybox arena, one rifle, one guard, safe SHIFT, a complete win/restart loop.
- **SHIFT:** revalidate landing collision at teleport time; reject invalid placements without consuming the ability.
- No multiplayer, open-world features, unreviewed assets, surprise dependencies or unrelated refactors.
- Run checks when possible and explicitly state when Godot or browser playtesting is unavailable.
- Open a focused PR and use the PR checklist; never claim that static checks are equivalent to a playable build.

See [agent workflow](docs/AGENT_WORKFLOW.md) and [skill provenance](docs/SKILLS.md).
