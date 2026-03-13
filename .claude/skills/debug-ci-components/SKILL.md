---
name: debug-ci-components
description: Debug failing MediaWiki extension/skin CI component tests by checking the quickstart CI results page, reproducing failures locally, researching extension requirements, fixing quickstart config files, and re-running until tests pass.
---

# debug-ci-components

You are a CI debugger for **mediawiki-quickstart**. Your job is to check the
quickstart CI results page for failing components, then systematically fix them
by reproducing locally, researching requirements, updating quickstart config
files, and re-running until tests pass.

---

## 1 Requirements

This skill requires Chrome browser automation to view CI results. Before doing
anything else, call `mcp__claude-in-chrome__tabs_context_mcp` to verify Chrome
is available. If it is not:

1. Stop immediately.
2. Tell the user:
   > This skill requires browser automation. Please restart Claude Code with
   > the `--chrome` flag:
   >
   > ```
   > claude --chrome
   > ```
   >
   > Then invoke the skill again.
3. Do not proceed.

---

## 2 Check CI Results

1. Open `https://quickstart-ci-components.wmcloud.org` in Chrome.
2. Look at the most recent run. Identify components with failures at any stage:
   - `fresh_install` — MediaWiki core failed to install
   - `component_install` — the extension/skin failed to install
   - `selenium_tests_exist` — no selenium tests found (not a failure to fix)
   - `run_selenium_tests` — selenium tests failed
3. For each failing component, check whether it is also failing on Gerrit CI.
   Query the Gerrit API for recent open changes:

   ```bash
   curl -s "https://gerrit.wikimedia.org/r/changes/?q=project:mediawiki/<type>/<Name>+status:open&n=5"
   ```

   Look at the `submit_records` → `labels` → `Verified` field. If Jenkins
   (account 75) has set `"status": "REJECT"` on recent patches, the extension
   is **also broken on upstream CI** — meaning the failure is likely an upstream
   bug, not a quickstart config issue. Mark it as **Gerrit CI: failing**.

   Run these checks in parallel for all failing components to build the full
   picture quickly.

4. Present the failing components to the user in a table showing:
   - Component name
   - Which CI stage failed (`fresh_install`, `component_install`,
     `run_selenium_tests`)
   - Gerrit CI status (passing / failing)

   Then ask whether they want to choose a specific component or have you work
   through the list from top to bottom. If the user has already specified a
   component, skip this step.

---

## 3 Investigate the Failure

1. Open the failing component's log in Chrome:
   `https://quickstart-ci-components.wmcloud.org/api/results/<run_id>/<type>/<Name>/log.ansi.html`
2. Read through the log to identify the error. Common failure patterns:
   - **Git clone failures** — transient network errors (TLS, broken pipe)
   - **"Extension/skin cannot be loaded"** — missing dependency not installed
   - **Selenium test failures** — test-specific issues (missing config, timing,
     missing dependency causing rendering failures)
   - **Composer/npm failures** — dependency resolution problems
   - **Maintenance script failures** — database or config issues
3. Note the exact error message and stack trace.

---

## 4 Research Extension Requirements

When the failure suggests a missing dependency or misconfiguration:

1. Look up the extension's documentation on mediawiki.org:
   `https://www.mediawiki.org/wiki/Extension:<Name>`
   or for skins: `https://www.mediawiki.org/wiki/Skin:<Name>`
2. Check what the extension requires:
   - Required extensions/skins (list them in `dependencies.yml`)
   - Required `LocalSettings.php` configuration (`wfLoadExtension` call plus
     any `$wg` settings)
   - Required maintenance scripts to run after install (put in `setup.sh`)
   - Required services (define in component `docker-compose.yml`)
3. Cross-reference with the existing quickstart config files for the component
   in the `extensions/<Name>/` or `skins/<Name>/` directory.

---

## 5 Fix Quickstart Config Files

Each component's manifest folder (`extensions/<Name>/` or `skins/<Name>/` in
the quickstart root, NOT inside the `mediawiki/` directory) can contain:

- **LocalSettings.php** (required) — `wfLoadExtension('Name');` plus any
  `$wg` config variables the extension needs
- **dependencies.yml** (optional) — list of components that must be installed
  first, e.g.:
  ```yml
  - skins/Vector
  - extensions/Echo
  ```
- **setup.sh** (optional) — shell commands to run after install (runs in the
  mediawiki container with pwd `/var/www/html/w`). Do NOT put `composer
  install` or `npm install` here — the installer handles those automatically.
- **pages/** (optional) — XML page dump files to import on install
- **docker-compose.yml** (optional) — additional services the component needs

Make the minimum changes needed to fix the failure.

---

## 6 Reproduce and Verify Locally

Run the full cycle locally to test your fix:

```bash
FORCE=1 SKIP_COUNTDOWN=1 ./fresh_install
./install extensions/<Name>
./run_selenium_tests extensions/<Name>
```

For skins, replace `extensions/` with `skins/`.

Read the output carefully. If tests still fail, go back to step 3 and investigate
further.

---

## 7 Iterate

Repeat steps 3-6 until all selenium tests pass (or until you've confirmed the
failure is not caused by a quickstart config issue). Each iteration should start
with a fresh install to ensure the fix works from a clean state.

When debugging selenium test failures specifically:
- Read the test spec files at
  `mediawiki/extensions/<Name>/tests/selenium/specs/` to understand what the
  test does
- Check if the test relies on a specific skin, page content, or config setting
- Check if the test has timing issues (e.g., waiting for async operations)
- Use `VERBOSE=1` before the commands for detailed output

---

## 8 Report and Move On

Once tests pass locally (or you've determined the failure is not fixable via
quickstart config), print a summary for that component:

> **extensions/SomeName** — Fixed
> Gerrit CI: passing (or failing)
> Files modified: `extensions/SomeName/dependencies.yml`, `extensions/SomeName/LocalSettings.php`
> (or: Could not fix — [reason])

Do not commit. The user will review and commit the changes themselves.

If working through multiple components, continue to the next one automatically.
After all components are done, print a final summary listing each component and
its outcome.

If working on a single component, ask the user if they want to investigate
another failing component.

---

## 9 Rules

- **CI first.** Always start by checking CI results to see what's actually
  failing before doing anything locally.
- **Minimal fixes.** Only change what's needed to fix the failure. Don't
  refactor or add unnecessary config.
- **Fresh state.** Always test from a fresh install. Never assume state from a
  previous run.
- **Read before editing.** Always read existing config files before modifying
  them.
- **Quickstart config only.** You are modifying files in the quickstart root
  (`extensions/<Name>/`, `skins/<Name>/`), not files inside `mediawiki/`.
  Files inside `mediawiki/` are cloned from upstream and get wiped on fresh
  install.
- **Be concise.** Report what you found, what you changed, and whether it
  worked. No filler.
