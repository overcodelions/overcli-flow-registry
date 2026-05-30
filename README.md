# overcli Flow Registry

This directory is the source of truth for [github.com/overcodelions/overcli-flow-registry](https://github.com/overcodelions/overcli-flow-registry). Push updates to that repo's `main` branch after testing locally.

## Adding a flow

1. Create a flow YAML file in `flows/` following the schema in `overcli/src/shared/flows/schema.ts`:
   - Must have `input: user_prompt` (literal)
   - At least one step with `user_prompt` in its `inputs`
   - Valid role: `planner | implementer | plan-reviewer | reviewer | test-writer | researcher | shipper | custom`
   - Valid model backend: `claude` or `ollama`
   - Include `author` and `version` (e.g., `1.0.0`)

2. Tag your flow with 3–6 tags from `TAGS.md` (e.g., `[design, api, backend, claude]`)

3. Regenerate `index.json`:
   ```bash
   bash scripts/build-index.sh
   ```
   This computes sha256 hashes and validates all flows exist.

4. Create a pull request and merge to `main`.

> **Note:** `index.json` is auto-generated — do not edit it by hand. The build script ensures sha256 hashes match files on disk (`overcli/src/main/flows/registry.ts:101-104` validates this during install). Branch protection requires PR review before merge.

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
