## Purpose / design reference
<!-- Link the approved feature spec or explain why this is a straightforward fix. -->

## Milestone identity and tracking

- **Milestone:** MS-__ (or governance-only documentation PR)
- **Roadmap:** [docs/MILESTONES.md](../docs/MILESTONES.md)
- [ ] Exactly one implementation milestone is covered (or this PR is explicitly governance-only).
- [ ] Nested tasks in the milestone were ticked **only after actual verification**.
- [ ] Once all tasks/acceptance checks passed, the milestone is checked **in this PR** and its true PR link is recorded. If still open: state why.
- [ ] `python3 scripts/validate_milestones.py docs/MILESTONES.md` passed.
<!-- Do not check an unverified manual playtest or final itch.io submission. -->

## What changed
<!-- Describe behavior, not just file names. -->

## Tests actually run
- [ ] Static audit: `python3 .agents/skills/swapshot-review/scripts/audit_project.py --root .`
- [ ] Python audit tests: `python3 -m unittest discover -s .agents/skills/swapshot-review/tests -v`
- [ ] Godot headless import/startup (include exact version and command)
- [ ] Relevant manual gameplay scenarios (provide observations)
- [ ] Hosted Web export checked, when shipping browser changes
<!-- For NOT RUN items: explain environment/tool limitation. -->

## SWAPSHOT review
- [ ] Applied `swapshot-review` to changed paths and critical regressions
- [ ] All P0/P1 issues addressed or individually documented
- [ ] No unlicensed assets, secrets, unnecessary dependencies, or unrelated changes

## Screenshots / video / repro steps
<!-- For visual/gameplay PRs, provide proof or mark unavailable. -->

## Known limitations, risks, and rollback plan
