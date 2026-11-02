# Agentic development workflow

1. **Inspect** README, AGENTS, GAME_DESIGN, ARCHITECTURE, current code and issue.
2. **Brainstorm** creative changes using local `brainstorming` skill. Obtain design approval when required by that skill. Store substantial specs under `docs/superpowers/specs/YYYY-MM-DD-topic-design.md`.
3. **Plan** the smallest vertical slice, with acceptance criteria and failure/rollback path. If the upstream `writing-plans` companion skill is unavailable, document the plan in `docs/plans/` and clearly say no such skill was invoked.
4. **Implement** on a topic branch, keeping work reviewable. Avoid unplanned expansion.
5. **Verify** fresh checks: static audit, unit tests, Godot headless import, gameplay exercise and browser export if applicable. Show actual exit statuses and identify NOT RUN checks.
6. **Review** with `swapshot-review`; prioritize P0/P1 issues before polish.
7. **PR** with summary, changed behaviors, verification evidence, and manual playtest steps. Request review. Do not merge automatically.

Skills are local under `.agents/skills/`. The Claude wrappers in `.claude/skills/` point to those same full instructions. The skill finder may **recommend** additions, but no unreviewed skill is automatically authorized to install dependencies.

## Definition of done

Code exists in the PR; a relevant check was executed with passing output; no known P0/P1 in intended scope; all unavailable gameplay/engine/browser checks are explicitly listed. A CI green check alone does not verify aim feel, combat quality, FPS or player comprehension.
