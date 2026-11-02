# Play each SWAPSHOT PR in your browser

**Purpose:** Preview the gameplay associated with a PR before merging it. These
are development builds; browser acceptance and manual QA still need real
observations. This is **not** the final MS-14 Web export/itch.io release gate.

## Architecture and trust boundaries

1. `SWAPSHOT PR Web Preview Build` runs when a **same-repository PR**
   targeting `main` is opened or updated. It uses **read-only** checkout,
   pinned Godot **4.7.2 stable**, official Godot Web export templates,
   Compatibility rendering, **single-threaded** Web export, and an isolated
   temporary `export_presets.cfg` copied from
   `.github/web-preview-export-presets.cfg`. It checks for
   `index.html`, `index.js`, `index.wasm`, and `index.pck`, then uploads
   a short-lived artifact. The first official export-template download is
   roughly 1.2 GiB; Actions caches only the extracted Web template afterward.
2. `SWAPSHOT Publish PR Previews to Pages` runs in the **default branch**
   only after a successful export workflow. Its trusted code downloads the
   artifact but **never executes PR-supplied files**. It verifies the PR
   number, same-repo origin, open status, target `main`, and head SHA
   before proceeding. Stale runs are ignored.
3. The publisher stores each snapshot in `gh-pages/pr-N/`, writes a static
   index, and publishes the **whole collection** using GitHub Pages Actions.
   Previous PR URLs remain available unless intentionally cleaned up.
   All preview content is **public**; do not expose secrets or sensitive data.
   Artifacts/builds from forks are intentionally not published.

## One-time repository setup (required)

The owner must merge the **governance** PR containing these workflows first.
It must be merged independently of gameplay MS-01 and only after the
pre-merge review/CI checks pass. Then:

1. Go to **Settings → Pages → Build and deployment**.
2. Choose **GitHub Actions** as the publishing source.
3. Under **Settings → Environments → github-pages**, allow deployments from
   `main` (the trusted publishing workflow runs on `main`). Ensure the
   repository Actions permissions/ruleset allows this workflow to write to a
   new `gh-pages` branch; code on incoming PRs never has write permissions.
4. Refresh or synchronize an existing gameplay PR (for example, by pushing
   a commit or re-running its PR Web Preview Build workflow) to generate a
   preview artifact after the governance workflow has been merged.
5. Check the successful **Publish PR Previews to Pages** deployment job.
   Only then open the URL. A build artifact alone does not establish that
   GitHub Pages deployed or that the browser game runs correctly.

**Preview index (once deployed):**
https://mishraaditya595.github.io/swapshot/

**PR #4 example (once deployed):**
https://mishraaditya595.github.io/swapshot/pr-4/

For any later PR #N, use `https://mishraaditya595.github.io/swapshot/pr-N/`.
Each commit to a PR updates its snapshot, while other PR URLs remain stable.

## Browser QA

Use a desktop Chromium/Firefox browser supporting WebAssembly and WebGL 2.
Open the hosted URL, click the canvas to capture the pointer, move using WASD,
aim/look around walls, test the ramp and boundary collisions, press Escape to
release pointer lock, click again to recapture and alt-tab away/back. Record
browser/version, OS, commit SHA, pass/fail notes, and console errors in the
gameplay PR. A successful Pages deployment by itself is **not** evidence that
MS-01 (or another milestone) has passed manual acceptance.

## Failure handling / scope guard

- **Export job fails:** inspect the export log and `verify_web_preview.py`
  output. Do not publish a partially generated build.
- **Publisher skips:** its PR revision was superseded or PR was closed.
- **Publisher fails:** verify Pages source, deployment environment, branch
  permissions and `gh-pages` branch ruleset. The build artifact is still
  available for inspection within its retention period.
- **Browser fails:** check browser developer console, WebGL 2 availability,
  single-threaded export options, and asset load errors. Do not mark browser
  verification complete.
- **Large repository:** snapshots persist on `gh-pages`; prune old paths by
  a reviewed maintenance change if storage approaches GitHub Pages limits.
- **Final jam release:** MS-14/MS-15/MS-16 still require a tested hosted itch.io
  export and independent release evidence. Preview hosting does not replace it.

The infrastructure is intentionally a separate `ci:` governance PR. It does
not change any gameplay milestone checkbox or silently close MS-01.
