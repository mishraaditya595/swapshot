"""Unit tests for milestone tracker integrity rules."""
from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "validate_milestones.py"
spec = importlib.util.spec_from_file_location("swapshot_milestones", SCRIPT)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


def sample() -> str:
    lines = []
    for i in range(17):
        num = f"{i:02}"
        checked = "x" if i == 0 else " "
        pr = "[#1](https://github.com/mishraaditya595/swapshot/pull/1)" if i == 0 else "—"
        lines.extend([
            f"### MS-{num} — Test milestone", "",
            f"- [{checked}] **MS-{num} complete** — **Implementing PR:** {pr}",
            f"  - [{checked}] Do first task",
            f"  - [{checked}] Do second task",
            f"  - [{checked}] Do third task",
            "",
        ])
    return "\n".join(lines)


class MilestoneValidatorTest(unittest.TestCase):
    def test_baseline_passes(self):
        self.assertEqual(module.validate(sample()), [])

    def test_missing_milestone_detected(self):
        source = sample().replace("### MS-07 — Test milestone", "### MS-09 — Test milestone")
        self.assertTrue(module.validate(source))

    def test_checked_without_pr_fails(self):
        source = sample().replace(
            "[#1](https://github.com/mishraaditya595/swapshot/pull/1)", "—", 1
        )
        self.assertTrue(any("requires a matching GitHub PR" in e for e in module.validate(source)))

    def test_checked_with_unfinished_task_fails(self):
        source = sample().replace("  - [x] Do first task", "  - [ ] Do first task", 1)
        self.assertTrue(any("unchecked tasks" in e for e in module.validate(source)))

    def test_duplicate_pr_fails(self):
        source = sample()
        source = source.replace(
            "- [ ] **MS-01 complete** — **Implementing PR:** —",
            "- [x] **MS-01 complete** — **Implementing PR:** [#1](https://github.com/mishraaditya595/swapshot/pull/1)",
        )
        source = source.replace("### MS-01 — Test milestone\n\n- [x]", "### MS-01 — Test milestone\n\n- [x]")
        # Mark the three tasks under MS-01 as checked.
        before, rest = source.split("### MS-01 — Test milestone", 1)
        current, after = rest.split("### MS-02 — Test milestone", 1)
        current = current.replace("  - [ ]", "  - [x]")
        source = before + "### MS-01 — Test milestone" + current + "### MS-02 — Test milestone" + after
        self.assertTrue(any("already assigned" in e for e in module.validate(source)))


if __name__ == "__main__":
    unittest.main()
