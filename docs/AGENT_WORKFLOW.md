# Agentic development workflow

1. **Inspect** README, AGENTS, GAME_DESIGN, ARCHITECTURE, current code and issue.
2. **Brainstorm** creative changes using local `brainstorming` skill. Obtain design approval when required by that skill. Store substantial specs under `docs/superpowers/specs/YYYY-MM-DD-topic-design.md`.
3. **Plan** the smallest vertical slice, with acceptance criteria and failure/rollback path. If the upstream `writing-plans` companion skill is unavailable, document the plan in `docs/plans/` and clearly say no such skill was invoked.
4. **Implement** on a topic branch, keeping work reviewable. Avoid unplanned expansion.
5. **Verify** fresh checks: static audit, unit tests, Godot headless import, gameplay exercise and browser export if applicable. Show actual exit statuses and identify NOT RUN checks.
6. **Review** with `swapshot-review`; prioritize P0/P1 issues before polish.
7. **PR** with summary, changed behaviors, verification evidence, and manual playtest steps. Request review. Do not merge automatically.

Skills are local under `.agents/skills/`. The Claude wrappers in `.claude/skills/` point to those same full instructions. The skill finder may **recommend** additions, but no unreviewed skill is automatically authorized to install dependencies.

## Milestone execution and reporting (mandatory)

Read `docs/MILESTONES.md` before implementing any feature; choose **one** milestone (MS-01 through MS-16) and create **one** implementing PR. PR title/body must include its stable ID. A milestone has an ordered task checklist and an acceptance gate; complete and verify tasks individually, updating `docs/MILESTONES.md` **in the same PR**. Once all requirements pass, change the milestone's checkbox to [x] and replace its PR placeholder with the genuine GitHub PR link. Create the PR first to learn the real number; add a follow-up commit for the tracker update. Never invent PR numbers or mark manual/human-dependent tests complete without evidence.

A governance-only PR that changes the milestone process is not a gameplay milestone. For user-approved scope changes, update the planned work by reviewed PR and preserve historical completed IDs and links. Run `python3 scripts/validate_milestones.py docs/MILESTONES.md` and its tests. Static validation cannot replace in-engine or hosted browser verification.

## Enforced pre-merge pipeline

Read [PRE_MERGE.md](PRE_MERGE.md) and submit a milestone PR or governance-only PR using its exact classification format. GitHub runs two additional jobs: **PR milestone acceptance** (roadmap state, real PR link, prerequisites, evidence headings) and **Automated code review** (secret/artifact/unsafe API detection and project-specific manual review reminders). Failing either check must prevent merge once branch ruleset requirements are enabled. These checks cannot verify manual playtesting or full code quality; perform human review and in-engine QA separately.

## Definition of done

Code exists in the PR; a relevant check was executed with passing output; no known P0/P1 in intended scope; all unavailable gameplay/engine/browser checks are explicitly listed. A CI green check alone does not verify aim feel, combat quality, FPS or player comprehension.
