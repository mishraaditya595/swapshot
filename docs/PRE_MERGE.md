# SWAPSHOT pre-merge quality gate

## What runs

Each GitHub pull request targeting main triggers **SWAPSHOT CI** and **SWAPSHOT Pre-Merge**, with these stable job names:

| Job name | Behavior |
| --- | --- |
| Static audit and audit tests | Existing source resource checks, audit unit tests, milestone format validator, milestone validator tests plus PR-review unit tests |
| Godot 4.7.2 headless import | Imports and starts Godot project; scans logs for engine/script errors |
| PR milestone acceptance | Enforces one milestone per PR, checked tasks, actual PR link, prior milestone completion, PR evidence headings; governance-only PRs cannot modify gameplay |
| Automated code review | Scans changed paths/diff for committed secrets, generated builds/editor caches, oversized files, and unsafe execution APIs; emits explicit SHIFT/combat/asset/workflow review reminders |

The last two jobs publish a Markdown report in **Actions → Job summary** and an artifact. They use read-only tokens on untrusted PR branches; no API key, AI service, privileged \`pull_request_target\` event or write token is needed.

**Important:** This is a conservative static code review, **not** an autonomous AI reviewer and **not** proof that the game plays well. It cannot establish player feel, Godot runtime correctness, safe SHIFT landing, FPS, browser pointer lock, the contents of third-party assets, or successful jam submission. A developer must review the diff and all gameplay acceptance evidence. When new GDScript tests are added, the engine CI should exercise them in addition to import.

## How to prepare a gameplay PR

1. Work on **one** MS-XX milestone, as defined in \`docs/MILESTONES.md\`.
2. Open the PR early to obtain its real number.
3. Title: \`MS-01: third-person movement and greybox arena\` (replace with your milestone).
4. PR body includes **exactly one** \`**Milestone:** MS-01\` field and substantive Markdown sections:
   - \`## Acceptance evidence\`: acceptance gate, relevant manual playtest link/notes and results.
   - \`## Verification evidence\`: actual commands, exit status, screenshots or captured logs, and explicitly unrun checks.
   - \`## Review findings\`: results from \`swapshot-review\`, unresolved defects/risk.
5. Tick all verified nested tasks and the milestone in \`docs/MILESTONES.md\`. The completed milestone line must have a link to **this** implementing PR, e.g. \`[#7](https://github.com/mishraaditya595/swapshot/pull/7)\`.
6. Push the tracker update and wait for fresh checks. Before merging, resolve P0/P1 review findings and have a human check manual test claims.

The PR policy check **intentionally fails** for an unfinished milestone. Keep such PRs in draft; it is a readiness gate, not an automatic status updater. Don't invent evidence just to make CI green.

## How to prepare an infrastructure-only PR

Use a title starting with \`ci:\`, \`docs:\`, or \`chore:\`. Include **exactly** the line \`**Change type:** governance\` in the PR body. This path is for instructions, docs, Python CI tooling, agent skills and workflow maintenance, **not** game scenes, scripts, assets or changes to completed milestone status. Future legitimate exceptions need an explicitly reviewed change to these rules, never a misleading milestone completion.

## Enable merge enforcement in GitHub

A GitHub Actions job running successfully is not automatically mandatory. At **Settings → Rules → Rulesets → Protect Main - CI Required**, select these four required status checks, with expected source GitHub Actions:

- \`Static audit and audit tests\`
- \`Godot 4.7.2 headless import\`
- \`PR milestone acceptance\`
- \`Automated code review\`

Keep the ruleset active, require PRs, reject force pushes/deletion, and require branches to be current. The two pre-merge job names may first appear in the dropdown after their workflow has run in a PR. If GitHub does not list them yet, wait until the jobs complete or enter the exact check names if the UI supports it.

On a solo-owned repository, required human approvals may remain **0**. This does **not** replace intentional review of the changed code or real in-engine testing; GitHub's 0-approval configuration permits the author to merge after automated checks pass. If you later add reviewers, require at least one approval.

## Run locally

\`\`\`bash
python3 -m unittest discover -s tests -v
python3 scripts/validate_milestones.py docs/MILESTONES.md
\`\`\`

For PR policy/review with an event payload and full Git history:

\`\`\`bash
python3 scripts/pr_quality.py policy --event path/to/pr-event.json
python3 scripts/pr_quality.py review --event path/to/pr-event.json
\`\`\`

A failed gate must be addressed with a new commit, not bypassed. If the gate itself is wrong, make a separately reviewed governance PR to fix and test the rule.
