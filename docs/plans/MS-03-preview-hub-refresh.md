# Development preview hub refresh

**Scope:** Requested addition to draft PR #11 alongside MS-03 SHIFT safety. This is a presentation change to the existing manually published GitHub Pages hub. It does not add a gameplay milestone or change the deployment trigger.

## Design rationale

The prior hub consisted of a centered title and a list of plain links. The refreshed page uses SWAPSHOT's graphite environment, cyan SHIFT accents and an industrial silhouette illustration. The main action launches the published main build when present, otherwise the highest-numbered available PR snapshot. Build cards distinguish main from PR revisions and link back to the corresponding code and tests.

The page is responsive and keyboard navigable, with an accessible skip link, visible focus states, semantic sections and a reduced-motion media query. The illustration is labelled as conceptual art, not a game screenshot. No fonts, external images, scripts or packages are required.

## Availability and safety

The existing `.github/scripts/render_pr_previews.py` remains the trusted source of the page. Only directories containing `index.html` appear as playable builds. Relative `play/` and `pr-N/` URLs are preserved. Publishing remains an owner-triggered action; PR updates and merges do not publish builds. The manual GitHub Pages workflow deliberately executes this script from `main`, so this hub redesign will appear publicly only after it reaches `main` and the owner next runs the deployment workflow. A preview of PR #11's game therefore does not demonstrate the new hub UI.

The updated generator is covered by `tests/test_preview_hub.py` and continues to use only Python's standard library. The test suite checks links and page states; rendered visual QA is a separate manual check.

## Design workflow

Reviewed the [SuperDesign skill](https://github.com/superdesigndev/superdesign-skill/tree/main/skills/superdesign) and its direct-authoring guidance. The SuperDesign CLI preflight timed out in this environment, so no SuperDesign canvas draft or model-generated mockup is claimed. The published HTML and CSS were authored directly for the existing generator. The upstream skill was consulted, not installed or copied into the game repository.

This owner-requested UI addition does not change MS-03 gameplay acceptance. PR #11 remains in draft until SHIFT browser playtesting is documented.
