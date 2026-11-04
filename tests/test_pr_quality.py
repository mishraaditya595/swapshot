"""Regression tests for SWAPSHOT's unprivileged pre-merge checks."""
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
from pr_quality import policy, static_review, section_body


def tracker(done=None, pr=1):
    done = {0} if done is None else set(done)
    lines = []
    for i in range(17):
        ch = "x" if i in done else " "
        url = f"[#{pr}](https://github.com/mishraaditya595/swapshot/pull/{pr})" if i in done and i != 0 else (
            "[#1](https://github.com/mishraaditya595/swapshot/pull/1)" if i == 0 else "—"
        )
        lines.extend([
            f"### MS-{i:02} — Example",
            f"- [{ch}] **MS-{i:02} complete** — **Implementing PR:** {url}",
            f"  - [{ch}] Task one", f"  - [{ch}] Task two", f"  - [{ch}] Task three", "",
        ])
    return "\n".join(lines)


def milestone_event(number=7, ident="MS-01", body=None):
    return {"number": number, "pull_request": {
        "number": number, "title": f"{ident}: movement and camera",
        "base": {"ref": "main"},
        "body": body if body is not None else (
            f"**Milestone:** {ident}\n\n"
            "## Acceptance evidence\nController tested in editor; screenshot and manual notes attached.\n\n"
            "## Verification evidence\nGodot headless import passed and manual gameplay test documented.\n\n"
            "## Review findings\nNo unresolved P0/P1 issues; human review requested before merge.\n"
        ),
    }}


class PRQualityTests(unittest.TestCase):
    def test_complete_milestone_passes(self):
        failures, _ = policy(milestone_event(), ["docs/MILESTONES.md", "scenes/player/player.tscn"],
                             tracker(), tracker({0, 1}, pr=7))
        self.assertEqual(failures, [])

    def test_incomplete_milestone_blocks(self):
        failures, _ = policy(milestone_event(), ["docs/MILESTONES.md"], tracker(), tracker())
        self.assertTrue(any("must be checked" in f for f in failures))

    def test_wrong_pr_link_blocks(self):
        failures, _ = policy(milestone_event(), ["docs/MILESTONES.md"], tracker(), tracker({0, 1}, pr=99))
        self.assertTrue(any("actual implementing PR" in f for f in failures))

    def test_skipped_milestone_blocks(self):
        failures, _ = policy(milestone_event(8, "MS-02"), ["docs/MILESTONES.md"],
                             tracker(), tracker({0, 2}, pr=8))
        self.assertTrue(any("prerequisite" in f for f in failures))

    def test_governance_allows_documentation_ci(self):
        e = milestone_event()
        e["pull_request"]["title"] = "ci: add pre-merge checks"
        e["pull_request"]["body"] = "**Change type:** governance"
        failures, _ = policy(e, ["scripts/pr_quality.py", "tests/test_pr_quality.py",
                                 ".github/workflows/premerge.yml", "AGENTS.md"], tracker(), tracker())
        self.assertEqual(failures, [])

    def test_governance_disallows_game_changes(self):
        e = milestone_event()
        e["pull_request"]["title"] = "ci: checks"
        e["pull_request"]["body"] = "**Change type:** governance"
        failures, _ = policy(e, ["scenes/main.tscn"], tracker(), tracker())
        self.assertTrue(any("implementation files" in f for f in failures))

    def test_body_requires_evidence(self):
        e = milestone_event(body="**Milestone:** MS-01")
        failures, _ = policy(e, ["docs/MILESTONES.md"], tracker(), tracker({0, 1}, pr=7))
        self.assertTrue(any("Acceptance evidence" in f for f in failures))

    def test_governance_cannot_complete_milestones(self):
        e = milestone_event()
        e["pull_request"]["title"] = "docs: governance"
        e["pull_request"]["body"] = "**Change type:** governance"
        failures, _ = policy(e, ["docs/MILESTONES.md"], tracker(), tracker({0, 1}, pr=7))
        self.assertTrue(any("preserve existing completion status" in f for f in failures))

    @staticmethod
    def _poc_event(number=20, issues="#19, #21"):
        event = milestone_event(number, "MS-09")
        event["pull_request"]["body"] += f"\n**POC deferral:** {issues}\n"
        return event

    @staticmethod
    def _ms09_tracker(number=20):
        result = tracker()
        old = "- [ ] **MS-09 complete** — **Implementing PR:** —"
        new = (f"- [ ] **MS-09 complete** — **Implementing PR:** "
               f"[#{number}](https://github.com/mishraaditya595/swapshot/pull/{number})")
        assert old in result
        return result.replace(old, new)

    def test_approved_poc_can_defer_ms09_and_predecessors(self):
        failures, notes = policy(
            self._poc_event(),
            ["docs/MILESTONES.md", "scenes/levels/security_core.tscn"],
            tracker(), self._ms09_tracker()
        )
        self.assertEqual(failures, [])
        self.assertTrue(any("not final milestone or release acceptance" in n for n in notes))

    def test_poc_without_approved_issue_list_fails(self):
        for wrong in ["#19", "#21, #19", "#19, #22"]:
            with self.subTest(wrong=wrong):
                failures, _ = policy(
                    self._poc_event(issues=wrong), ["docs/MILESTONES.md"],
                    tracker(), self._ms09_tracker()
                )
                self.assertTrue(any("not approved" in f for f in failures))

    def test_poc_other_pr_number_cannot_opt_in(self):
        failures, _ = policy(
            self._poc_event(number=22), ["docs/MILESTONES.md"],
            tracker(), self._ms09_tracker(22)
        )
        self.assertTrue(any("not approved" in f for f in failures))

    def test_poc_without_explicit_opt_in_still_fails(self):
        failures, _ = policy(
            milestone_event(20, "MS-09"), ["docs/MILESTONES.md"],
            tracker(), self._ms09_tracker()
        )
        self.assertTrue(any("must be checked" in f for f in failures))

    def test_poc_cannot_skip_actual_pr_link(self):
        failures, _ = policy(
            self._poc_event(), ["docs/MILESTONES.md"], tracker(), tracker()
        )
        self.assertTrue(any("actual implementing PR" in f for f in failures))

    def test_poc_cannot_change_predecessor_tasks(self):
        updated = self._ms09_tracker().replace(
            "  - [ ] Task two\n", "  - [x] Task two\n", 1
        )
        failures, _ = policy(
            self._poc_event(), ["docs/MILESTONES.md"], tracker(), updated
        )
        self.assertTrue(any("cannot change" in f or "invalid" in f for f in failures))

    def test_poc_rejects_duplicate_fields(self):
        event = self._poc_event()
        event["pull_request"]["body"] += "\n**POC deferral:** #19, #21\n"
        failures, _ = policy(
            event, ["docs/MILESTONES.md"], tracker(), self._ms09_tracker()
        )
        self.assertTrue(any("Exactly one POC deferral field" in f for f in failures))

    def test_poc_does_not_bypass_evidence_sections(self):
        event = self._poc_event()
        event["pull_request"]["body"] = "**Milestone:** MS-09\n**POC deferral:** #19, #21"
        failures, _ = policy(
            event, ["docs/MILESTONES.md"], tracker(), self._ms09_tracker()
        )
        self.assertTrue(any("Acceptance evidence" in f for f in failures))

    def test_secret_is_blocking_and_redacted(self):
        token = "ghp_" + "a" * 30
        findings, _ = static_review(["scripts/test.gd"], "diff --git a/scripts/test.gd b/scripts/test.gd\n+" + token, Path("."))
        self.assertTrue(any("credential" in f for f in findings))
        self.assertFalse(any(token in f for f in findings))

    def test_unsafe_eval_is_blocked(self):
        failures, _ = static_review(["scripts/main.gd"], "diff --git a/scripts/main.gd b/scripts/main.gd\n+OS.execute(\"bad\")", Path("."))
        self.assertTrue(any("evaluation API" in f for f in failures))

    def test_build_artifacts_blocked(self):
        failures, _ = static_review([".godot/imported/test.bin", "build/web/index.html"], "", Path("."))
        self.assertEqual(len(failures), 2)

    def test_review_adds_shift_warning(self):
        failures, notes = static_review(["scenes/abilities/shift.gd"], "", Path("."))
        self.assertFalse(failures)
        self.assertTrue(any("capsule clearance" in n for n in notes))

    def test_substantive_section_parser(self):
        self.assertIn("Evidence here", section_body("## Acceptance evidence\nEvidence here\n## Review findings\nOK", "Acceptance evidence"))


if __name__ == "__main__":
    unittest.main()
