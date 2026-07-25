# Flow tag taxonomy

Tags are lowercase, hyphen-separated, drawn from the controlled
vocabulary below. Each flow should carry 3–6 tags: at least one
**activity**, one **surface**, and one **backend**.
`scripts/build-index.sh` reads this file and fails the build on a tag
that isn't listed here, so keep it in sync with
`overcli/src/shared/flows/tagTaxonomy.ts` (which drives the filter chips
in the Browse Library modal).

## Activity
triage, review, design, planning, research, implementation, testing,
refactor, documentation, operations, security, release, migration,
debugging, analysis, communication

## Surface
tickets, prs, issues, confluence, docs, email, calendar, roadmap,
productboard, feedback, repo, logs, ci, infra

## Domain
frontend, backend, api, data, mobile, ux, devops

## Backend
claude, codex, ollama, mcp-jira, mcp-confluence, mcp-github, mcp-gmail,
mcp-drive
