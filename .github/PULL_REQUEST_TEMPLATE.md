## Purpose / design reference
<!-- Link the approved feature spec or explain why this is a straightforward fix. -->

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
