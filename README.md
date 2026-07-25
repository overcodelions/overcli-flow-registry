# overcli Flow Registry

This directory is the source of truth for [github.com/overcodelions/overcli-flow-registry](https://github.com/overcodelions/overcli-flow-registry). Push updates to that repo's `main` branch after testing locally.

## Adding a flow

1. Create a flow YAML file in `flows/` following the schema in `overcli/src/shared/flows/schema.ts`:
   - Must have `input: user_prompt` (literal)
   - At least one step with `user_prompt` in its `inputs`
   - Valid role: `planner | implementer | plan-reviewer | reviewer | test-writer |
     researcher | shipper | technical-writer | editor | debugger | code-reader |
     code-reviewer | security-reviewer | adversarial-reviewer | custom`
     (`custom` requires a `system_prompt`)
   - Valid model backend: `claude | codex | gemini | copilot | ollama`. Models must
     appear in `PREMIUM_MODELS` in `overcli/src/shared/modelCatalog.ts`
   - Include `author` and `version` (e.g., `1.0.0`) — bump `version` on every change,
     since the registry installs on the `(id, version)` pair

2. Tag your flow with 3–6 tags from `TAGS.md` (e.g., `[design, api, backend, claude]`)

3. Regenerate `index.json`:
   ```bash
   bash scripts/build-index.sh
   ```
   This computes sha256 hashes, reads `name`/`description`/`version`/`author`/`tags`
   off each YAML, and refuses to write the index if any flow is missing metadata or
   carries a tag outside `TAGS.md`.

4. Create a pull request and merge to `main`.

> **Note:** `index.json` is auto-generated — do not edit it by hand. The build script ensures sha256 hashes match files on disk (`overcli/src/main/flows/registry.ts:101-104` validates this during install). Branch protection requires PR review before merge.

## Flow conventions

These are conventions, not schema rules — the loader accepts flows that break them,
but every flow in this registry follows them.

- **Thread `user_prompt` into every step.** Steps only see what's in their `inputs`,
  so a step that omits `user_prompt` loses whatever the user typed at launch (scope,
  target, constraints). It's a short string; pass it everywhere.
- **Give critics their own participant.** Each participant runs *one* persistent
  conversation across every step it owns, so a `verify`/`review` step assigned to the
  same participant that produced the work is reviewing itself with full memory of its
  own reasoning. Verification steps get a fresh participant. (Deliberate exception:
  `plan` → `review` on one participant, so the planner remembers its plan.)
- **Gate anything that writes to the outside world.** Steps that create Jira tickets,
  publish Confluence pages, comment on issues, or open PRs set `pause_before: true`.
  Flows default to `bypassPermissions` when `permission_mode` is unset
  (`overcli/src/main/flows/runtime.ts`), so without the pause they fire unattended.
- **Use the backend's tool names.** `claude`/`codex`/`gemini`/`copilot` steps use
  `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `WebFetch`; only `ollama` steps use
  `read_file`, `list_dir`, `grep`, `write_file`, `edit_file`, `bash`. Mixing them means
  the builder's tool picker shows the step as having no tools selected.
- **Don't set `permission_mode: acceptEdits` on a step that needs to run commands** —
  it blocks `Bash`, so a fix step can't run the test it just wrote. Leave it unset
  (the runtime picks) for build/fix/test steps; use it for pure file-writing steps.
- **Name participants for their role, not their model** (`Scout`, `Builder`,
  `Reviewer`). The run UI shows these as tab labels, and model-derived names go stale
  on every model bump. Set `kind` on each: at most one `primary`, one `worker`, and
  one `reviewer`; everything else is `custom`.

## Hosting on a private repo

Any HTTPS endpoint that serves `index.json` and the referenced `flows/*.yaml`
files works. Add the registry in Settings → Flows → Add registry and put the
provider's bearer/basic token in **Auth header** — the value is sent verbatim
as the `Authorization` header.

- **GitHub (private)** — index URL:
  `https://raw.githubusercontent.com/<org>/<repo>/<branch>/index.json`
  Auth: `Bearer ghp_…` (fine-grained PAT with Contents: Read).
- **Bitbucket Cloud (private)** — index URL:
  `https://api.bitbucket.org/2.0/repositories/<workspace>/<repo>/src/<branch>/index.json`
  Auth: `Basic ` + base64(`<username>:<app-password>`), OR `Bearer <workspace-token>`.
  Keep `index.json` in the same directory as `flows/` so relative `yaml_url`
  values resolve.
- **Bitbucket Server / Data Center** — index URL:
  `https://<host>/projects/<KEY>/repos/<slug>/raw/index.json?at=refs/heads/<branch>`
  Auth: `Bearer <personal-access-token>`.
- **GitLab (private)** — index URL:
  `https://gitlab.com/api/v4/projects/<id>/repository/files/index.json/raw?ref=<branch>`
  Auth: `Bearer <project-access-token>`.
