"""Contract tests for the generated static GitHub Pages build hub."""
from __future__ import annotations

import importlib.util
import tempfile
import unittest
from html.parser import HTMLParser
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / ".github/scripts/render_pr_previews.py"
SPEC = importlib.util.spec_from_file_location("render_pr_previews", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
hub = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(hub)


class LinkParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.links: list[str] = []
        self.ids: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        attributes = dict(attrs)
        if tag == "a":
            self.links.append(attributes.get("href") or "")
        if attributes.get("id"):
            self.ids.append(attributes["id"] or "")


class PreviewHubTests(unittest.TestCase):
    def test_collects_only_published_snapshot_directories(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            site = Path(temporary)
            for name in ("pr-4", "pr-8", "pr-11", "pr-oops", "play"):
                (site / name).mkdir()
            for name in ("pr-4", "pr-8", "play"):
                (site / name / "index.html").write_text("ok")
            self.assertEqual(hub.collect_previews(site), [8, 4])

    def test_render_main_and_pr_links(self) -> None:
        document = hub.render([11, 8, 4], has_main=True)
        links = LinkParser()
        links.feed(document)
        self.assertEqual(document.count('class="build-card'), 4)
        for expected in ("play/", "pr-11/", "pr-8/", "pr-4/"):
            self.assertIn(expected, links.links)
        for num in (11, 8, 4):
            self.assertIn(
                f"https://github.com/mishraaditya595/swapshot/pull/{num}",
                links.links,
            )
        self.assertIn("04</strong> available snapshots", document)
        self.assertIn("DON'T TAKE", document)
        self.assertIn("SHIFT.", document)
        self.assertIn("manual", document.lower())
        self.assertIn("content", links.ids)
        self.assertIn("builds", links.ids)

    def test_pr_only_has_no_unpublished_main_link(self) -> None:
        document = hub.render([11], has_main=False)
        links = LinkParser()
        links.feed(document)
        self.assertNotIn("play/", links.links)
        self.assertEqual(links.links.count("pr-11/"), 2)
        self.assertIn("01</strong> available snapshots", document)

    def test_empty_site_has_noninteractive_hero_and_helpful_message(self) -> None:
        document = hub.render([], has_main=False)
        links = LinkParser()
        links.feed(document)
        self.assertIn("Awaiting first build", document)
        self.assertIn("No preview builds published yet", document)
        self.assertNotIn("play/", links.links)
        self.assertNotIn("pr-1/", links.links)

    def test_main_only(self) -> None:
        document = hub.render([], has_main=True)
        links = LinkParser()
        links.feed(document)
        self.assertIn("play/", links.links)
        self.assertNotIn("No preview builds published yet", document)


if __name__ == "__main__":
    unittest.main()
