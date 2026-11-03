# Manually deploy SWAPSHOT to GitHub Pages

GitHub Pages serves optional, **owner-triggered** playable Godot Web builds.
Nothing is published automatically when a PR is opened, updated, reopened,
closed, or merged, or when changes reach `main`. The usual CI/pre-merge tests
continue to run normally; those tests do **not** deploy to the web.

## How to run a deployment

First merge the separate governance [PR #5](https://github.com/mishraaditya595/swapshot/pull/5)
into `main`; the manual workflow button will not be active on `main` until then.
Configure **Settings → Pages → Build and deployment → GitHub Actions**.
Allow `main` to deploy to the `github-pages` environment. Ensure Actions can
create/update the `gh-pages` branch (branch rulesets may need an exception).

1. Open [Actions → SWAPSHOT Deploy Web to GitHub Pages (Manual)](https://github.com/mishraaditya595/swapshot/actions/workflows/deploy-web-manual.yml).
2. Select **Run workflow** and choose **Branch: main**. Runs from any other
   branch are explicitly blocked.
3. For an unmerged PR, set **source = pr**, enter the **PR number** (e.g. `4`),
   then click **Run workflow**. Only *open*, same-repository PRs targeting
   `main` are supported. The workflow resolves the current PR head SHA itself.
4. To deploy the latest merged game, set **source = main** and leave PR number
   **blank**. This checks out the latest `main` commit.
5. Open the completed workflow run. Only after the **Deploy selected revision
   to GitHub Pages** job succeeds should you use its deployment URL. Pages
   publishing success does not replace hands-on browser gameplay QA.

## Manually published URLs

- **Index:** https://mishraaditya595.github.io/swapshot/
- **Selected PR #4:** https://mishraaditya595.github.io/swapshot/pr-4/
- **Any PR #N:** `https://mishraaditya595.github.io/swapshot/pr-N/`
- **Latest manually deployed main:** https://mishraaditya595.github.io/swapshot/play/

The URLs above are intended routes, not evidence they are already live.
A successful manual run replaces *only* the selected snapshot. Other manual
PR snapshots remain available. `play/` is updated **only when you explicitly
run the workflow with source = main**; a merge does not update it.

## Security and release boundaries

The manual workflow `.github/workflows/deploy-web-manual.yml` has
**only** the `workflow_dispatch` event; it has no `push`,
`pull_request`, `workflow_run`, or scheduled deployment trigger.
The workflow has these separate jobs:

1. **Resolve:** on trusted `main`, validate the chosen PR or latest main
   SHA and reject any other workflow branch, fork PR, closed PR, or PR not
   targeting `main`.
2. **Build:** check out the selected game code with **read-only** permissions
   and credential-free checkout. Use a separate trusted checkout from `main`
   for the Web preset and structural verifier. Godot **4.7.2 stable** exports
   with the official **single-threaded Web templates** and Compatibility
   renderer. A full official export-template archive is downloaded on a cache
   miss (about 1.2 GiB).
3. **Stage:** check the PR/main SHA is still current, verify artifact files
   again with trusted code, preserve previous snapshots in `gh-pages`, and
   upload the complete Pages site. This job has repository write permission,
   but it never executes files from the selected game revision or artifact.
4. **Deploy:** use Pages permissions to publish the staged site and expose the
   URL in the job summary.

All previews are publicly accessible. Do not include secrets in the game or
export package. GitHub Pages storage is finite; old snapshot directories can
be pruned through a reviewed infrastructure change when needed. The
`gh-pages` branch is an archive, **not** a separate GitHub Pages build source:
the Pages source must be **GitHub Actions**.

The Web build step checks that `index.html`, `index.js`, `index.wasm`,
and `index.pck` are present and non-empty. A successful export does **not**
prove WebGL rendering, player controls, pointer lock, or gameplay correctness.
For MS-01 manual acceptance, use the hosted URL to test WASD, camera pitch,
walls/cover, ramp ascent/descent, click-to-capture, Escape-to-release, and
Alt-Tab focus behavior. Record browser version, OS, commit SHA, pass/fail
results, and console errors in the gameplay PR. Do not mark a milestone
accepted from automated checks alone.

This preview process does not replace the final tested itch.io release or
submission requirements in MS-14 through MS-16.

## Failure cases

- **No Run workflow button:** this PR is not yet on `main`; merge the
  infrastructure first, enable GitHub Actions and inspect workflow visibility.
- **Invalid PR number:** select source `pr`, enter an open same-repo PR number.
- **PR/main moved during export:** the job refuses to publish a stale build;
  trigger a fresh run manually.
- **Export fails:** inspect Godot import/export logs and structural asset check.
  No Pages deployment follows a failed build.
- **Stage/publish fails:** confirm Pages source, `github-pages` environment,
  Actions permissions and `gh-pages` branch protection.
- **Web loads incorrectly:** inspect the browser console/network and WebGL 2
  support; deployment itself does not certify a working game.
