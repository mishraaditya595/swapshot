"""Tests for the stdlib project audit; not gameplay tests."""
import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "audit_project.py"
spec = importlib.util.spec_from_file_location("swapshot_audit", SCRIPT)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class AuditTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def put(self, path, content):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")

    def minimal(self):
        self.put("project.godot", '[application]\nrun/main_scene="res://scenes/main.tscn"\n')
        self.put("scenes/main.tscn", '[gd_scene format=3]\n[node name="Root" type="Node3D"]\n')

    def rules(self, release=False):
        return {x["rule"] for x in module.audit(self.root, release)["findings"]}

    def test_empty_repo_fails(self):
        self.assertIn("PROJECT_MISSING", self.rules())

    def test_minimal_project_passes(self):
        self.minimal()
        self.assertEqual(module.audit(self.root)["result"], "PASS")

    def test_missing_main_scene(self):
        self.minimal()
        self.put("project.godot", '[application]\nrun/main_scene="res://scenes/absent.tscn"\n')
        self.assertIn("MAIN_SCENE_INVALID", self.rules())

    def test_broken_resource_reference(self):
        self.minimal()
        self.put("scripts/weapon.gd", 'extends Node\nvar tex = preload("res://assets/absent.png")\n')
        self.assertIn("MISSING_RESOURCE", self.rules())

    def test_dynamic_resource_ignored(self):
        self.minimal()
        self.put("scripts/weapon.gd", 'extends Node\nvar tex = "res://assets/%s.png"\n')
        self.assertNotIn("MISSING_RESOURCE", self.rules())

    def test_release_preset_required(self):
        self.minimal()
        self.assertIn("EXPORT_PRESET_MISSING", self.rules(release=True))
        self.put("export_presets.cfg", '[preset.0]\nplatform="Web"\n')
        self.assertEqual(module.audit(self.root, release=True)["result"], "PASS")


if __name__ == "__main__":
    unittest.main()
