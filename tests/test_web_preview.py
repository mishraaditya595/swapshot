import importlib.util
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


verify = load_module("verify_web_preview", ROOT / ".github/scripts/verify_web_preview.py")
index = load_module("render_pr_previews", ROOT / ".github/scripts/render_pr_previews.py")


class PreviewTests(unittest.TestCase):
    def test_missing_export_files_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            self.assertTrue(verify.errors_for(Path(tmp)))

    def test_complete_export_files_accepted(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            for filename in verify.REQUIRED:
                (folder / filename).write_text("index.wasm index.pck", encoding="utf-8")
            self.assertEqual([], verify.errors_for(folder))

    def test_invalid_html_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            for filename in verify.REQUIRED:
                (folder / filename).write_bytes(b"file")
            self.assertTrue(any("entrypoint" in issue for issue in verify.errors_for(folder)))

    def test_previews_sorted_and_empty_directory_ignored(self):
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            for name in ("pr-4", "pr-15", "pr-not-number", "pr-8"):
                (folder / name).mkdir()
            (folder / "pr-4/index.html").write_text("game", encoding="utf-8")
            (folder / "pr-15/index.html").write_text("game", encoding="utf-8")
            self.assertEqual([15, 4], index.collect_previews(folder))
            output = index.render(index.collect_previews(folder))
            self.assertLess(output.index("pr-15/"), output.index("pr-4/"))
            self.assertNotIn("pr-8/", output)

    def test_render_empty_index(self):
        self.assertIn("No preview builds", index.render([]))


if __name__ == "__main__":
    unittest.main()
