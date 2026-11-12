# overcli Flow Registry

The public library of ready-made [overcli](https://github.com/overcodelions/overcli) flows. Every overcli install lists it under **Settings → Flows**, and any flow here installs in one click from the flow picker.

Changes land through a pull request to `main`; test a flow locally before opening one.

## What's in it

38 flows. `index.json` is the canonical list; this table is a snapshot of it.

| Flow | What it does |
|---|---|
| **Analyze stack trace** | Parse the trace, locate frames in the codebase, diagnose root cause, then propose a fix |
| **API contract design** | Research existing endpoints, design the new contract, draft schemas, adversarially critique them, then fold the critique into a final contract |
| **Architecture Decision Record** | Research existing ADRs + context, design alternatives, draft the ADR, critique it, then fold the critique into a final ADR |
| **Changelog from commits** | Pull recent commits, group by conventional type, then emit polished CHANGELOG entries |
| **Close stale issues** | List issues, filter for staleness, draft close comments, then post on approval |
| **Code Review** | Survey the diff, review for correctness and security with independent reviewers, adversarially verify the findings, then format a final report |
| **Coverage gap report** | Diff recent changes, analyze test coverage, then format a gap report ranked by risk |
| **Data migration plan** | Survey current schema + scale, design an online migration with rollback, draft scripts, critique them for safety, then fold the critique into a final plan |
| **Data model design** | Research existing schema, design new tables/indexes/constraints, draft DDL, critique it for safety, then fold the critique into a final model |
| **Dead-code finder** | Scan for unreferenced symbols, verify each candidate is truly dead, then format a deletion plan |
| **Debug CI failure** | Gather CI logs + config, diagnose root cause, then propose a concrete fix |
| **Debug Error Logs** | Diagnose error logs, locate the failing code, draft a fix, verify it with an independent reviewer, then write up the result |
| **Dependency upgrade audit** | Scan installed deps, cross-check vulnerability feeds, analyze breakage risk, then format an upgrade plan |
| **Dockerfile review** | Read the Dockerfile and context, review for size/security/cache issues, then draft concrete fixes |
| **Estimate Jira ticket** | Fetch the ticket, scope it against the repo, weigh risks, then deliver story points with rationale |
| **Flaky test hunter** | Gather CI logs, identify flaky tests, diagnose causes, then draft fixes |
| **Generate Documentation** | Survey code, design a doc outline, draft each section, then polish for accuracy and prose |
| **Incident postmortem from notes** | Gather the incident record, build a timeline and root-cause analysis, draft the postmortem, critique it for blamelessness and completeness, then finalize |
| **Jira ticket to PR** | Fetch the ticket, design a plan, implement with a critic loop, review, apply a single fix pass, then open a PR on approval |
| **License audit** | Inventory dep licenses + repo LICENSE files, analyze for conflicts, then format an audit report |
| **On-call runbook** | Read the incident write-up, extract canonical steps, draft a runbook, critique it for completeness, then fold the critique into a final runbook |
| **Onboarding doc** | Survey the repo, outline an onboarding guide, draft each section, then polish |
| **Product idea → Jira tickets** | Turn a freeform product idea or feature brief into a Jira epic with implementation tickets, created on approval |
| **Productboard feature → Jira tickets** | Read a Productboard feature URL or description, break it into an epic + stories, then create them on approval |
| **Publish status to Confluence** | Pull recent Jira activity, summarize progress + blockers, draft a Confluence page with narrative flow, then publish on approval |
| **Release notes from PRs** | Gather merged PRs since last tag, categorize, then write user-facing release notes |
| **Search company knowledge** | Fan out searches across Confluence + Jira, deep-read top hits, then synthesize a cited answer |
| **Security review** | Map the diff, scan for OWASP-style issues, adversarially verify each finding with a fresh reviewer, then format a report |
| **Solve a ticket end-to-end** | Fetch a Jira ticket, design a plan, implement with a critic loop, review, apply a single fix pass, write tests, then open a PR on approval |
| **Spec → Jira tickets** | Fetch a Confluence spec, break it into an epic + stories, draft tickets, then create them on approval |
| **Sprint retrospective** | Pull sprint tickets, analyze wins/blockers/themes, then draft a retro doc |
| **Support ticket → Jira bug** | Convert a support ticket (Zendesk/email blob) into a well-structured Jira bug after checking for duplicates, then file it on approval |
| **System design doc** | Research the area, design alternatives, draft a full design doc, adversarially critique it, then fold the critique into a final doc |
| **Technical Q&A for Sales** | Answer a prospect's technical question from real evidence, adversarially fact-check every claim, then deliver both a send-ready customer response and the internal technical backing |
| **Terraform plan review** | Parse the plan, assess blast radius and rollback, then format a risk-ranked report |
| **Triage customer feedback** | Read customer feedback (email/transcript/blob), search Jira for duplicates, draft a ticket, then file it on approval |
| **Triage GitHub issue** | Fetch the issue, explore the repo, diagnose, then propose a resolution + labels |
| **Weekly status report** | Pull 7d of Jira activity, summarize themes, then format a status report |

## Adding a flow

1. Create a flow YAML file in `flows/` following the schema in `overcli/src/shared/flows/schema.ts`:
   - Must have `input: user_prompt` (literal)
   - At least one step with `user_prompt` in its `inputs`
   - Valid role: `planner | implementer | plan-reviewer | reviewer | test-writer |
     researcher | shipper | technical-writer | editor | debugger | code-reader |
     code-reviewer | security-reviewer | adversarial-reviewer | custom`
     (`custom` requires a `system_prompt`)
   - Valid model backend: `claude | codex | gemini | copilot | ollama`. Cloud models must
     appear in `PREMIUM_MODELS` in `overcli/src/shared/modelCatalog.ts` (retired ones are
     lifted to the next model in the same family on load); `ollama` steps take any local model
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

> **Note:** `index.json` is auto-generated — do not edit it by hand. The build script ensures sha256 hashes match files on disk (`loadEntryBody` in `overcli/src/main/flows/registry.ts` refuses to install a flow whose hash doesn't match). Branch protection requires PR review before merge.

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
- **Give every gating reviewer step a forward path, and never a backward one.**
  The runtime treats a `plan-reviewer` / `reviewer` / `code-reviewer` /
  `security-reviewer` / `adversarial-reviewer` step whose artifact has no
  `APPROVED` line as a *failed* step (`overcli/src/main/flows/runtime.ts` —
  `isGatingReviewerRole` + `isReviewApproved`). With the default `on_fail`
  that parks the run, so a review flow whose whole job is to report findings
  never reaches its `format` step. Set `on_fail: {action: goto, target: <the
  NEXT step>, max_retries: 1}` so a rejecting review flows into the step that
  consumes it. If a gating step is the last one, add the step that consumes it
  — a critic emits a verdict, not a deliverable.
- **A rejected review goes to a fix pass, not back to the builder.** `goto`
  targets must point *forward*. Bouncing to an earlier `build` step re-runs the
  implementer against its original `inputs`, which do not include the review —
  it has nothing new to work from, so the same diff comes back for the same
  rejection until `max_retries` runs out. A `fix` step placed after the review,
  taking `review.md` as an input, converges in one pass and cannot cycle.
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

## Hosting your own registry

### A local folder

The simplest private registry is a folder of `*.yaml` flows you already keep in git and
pull yourself. In **Settings → Flows → Add registry** pick **Local folder** and point it at
the folder. No `index.json` and no `sha256` are needed: overcli reads the folder, takes
`name`/`description`/`version`/`author`/`tags` off each YAML, and hashes each file itself
so an edit between listing and install is caught. It never runs git or fetches anything.

### A private remote

Any HTTPS endpoint that serves `index.json` and the referenced `flows/*.yaml`
files works. Add it in **Settings → Flows → Add registry → Remote URL** and put the
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
