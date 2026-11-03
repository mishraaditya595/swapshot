# Vendored agent skills and licensing

Five project-scoped skills are checked into `.agents/skills/`, and Claude Code discovery wrappers live in `.claude/skills/`. Canonical copies must be reviewed and intentionally updated; avoid network-installed skill drift.

| Skill | Origin | Canonical path |
| --- | --- | --- |
| brainstorming | [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/brainstorming) — [skills.sh](https://www.skills.sh/obra/superpowers/brainstorming) | `.agents/skills/brainstorming/SKILL.md` |
| find-skills | [vercel-labs/skills](https://github.com/vercel-labs/skills/tree/main/skills/find-skills) — [skills.sh](https://www.skills.sh/vercel-labs/skills/find-skills) | `.agents/skills/find-skills/SKILL.md` |
| verification-before-completion | [obra/superpowers](https://github.com/obra/superpowers/tree/main/skills/verification-before-completion) — [skills.sh](https://www.skills.sh/obra/superpowers/verification-before-completion) | `.agents/skills/verification-before-completion/SKILL.md` |
| humanizer | [blader/humanizer](https://github.com/blader/humanizer) — project-local install via `npx skills add blader/humanizer` | `.agents/skills/humanizer/SKILL.md` |
| swapshot-review | Custom skill based on SWAPSHOT's original design brief | `.agents/skills/swapshot-review/SKILL.md` |

**Humanizer upstream snapshot:** `blader/humanizer` main at `0ef9fe5bc3572734fd3ae6c448fe00a30cd5dcf0` (retrieved Nov 3, 2026). The complete upstream `SKILL.md` is vendored without edits; its MIT license is in `.agents/skills/_licenses/humanizer-MIT.txt`. Update by reviewing upstream changes and replacing the vendored copy intentionally, rather than relying on a global install. Claude Code uses a lightweight wrapper at `.claude/skills/humanizer/SKILL.md`.

**Upstream snapshots used for vendor copy (Nov 2, 2026):**
- `obra/superpowers` commit `2ce8aa15d05bd57213e6f746f953aafb7ded7a8b`
- `vercel-labs/skills` commit `92a9a34ac3bf88e695e468b90c7bf32f163d32c8`

The original three external skills are vendored from those exact upstream commits, including the brainstorming companion files. Their original MIT licenses are retained in `.agents/skills/_licenses/`. The custom reviewer is maintained for this game. Never remove or rewrite upstream copyright notices during updates.

**Note:** `brainstorming` may refer to other Superpowers skills (for example `writing-plans`) that are **not installed** by this bootstrap. Do not pretend they are available; request approval if further installation is needed or use `docs/plans/` as a local planning fallback.

The third-party `find-skills` skill contains CLI suggestions; reviewing/installing any *additional* external skill is a deliberate dependency change, not automatic permission to run untrusted code.
