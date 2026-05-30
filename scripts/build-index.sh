#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Build index.json from flows
{
  printf '{\n  "flows": [\n'
  first=1

  # Process each flow
  for yaml in flows/code-review.yaml flows/debug-logs.yaml flows/docs-from-code.yaml flows/solve-ticket.yaml \
              flows/triage-jira-bug.yaml flows/estimate-jira-ticket.yaml flows/jira-to-pr.yaml flows/sprint-retro.yaml \
              flows/weekly-status-report.yaml flows/spec-to-tickets.yaml flows/confluence-knowledge-search.yaml \
              flows/publish-status-to-confluence.yaml flows/triage-github-issue.yaml flows/release-notes-from-prs.yaml \
              flows/changelog-from-commits.yaml flows/pr-thorough-review.yaml flows/close-stale-issues.yaml \
              flows/on-call-runbook.yaml flows/analyze-stack-trace.yaml flows/dependency-upgrade-audit.yaml \
              flows/security-review.yaml flows/license-audit.yaml flows/dockerfile-review.yaml flows/ci-debug.yaml \
              flows/terraform-plan-review.yaml flows/adr-from-decision.yaml flows/system-design-doc.yaml \
              flows/api-contract-design.yaml flows/data-model-design.yaml flows/migration-plan.yaml \
              flows/onboarding-doc.yaml flows/flaky-test-hunter.yaml flows/coverage-gap-report.yaml flows/dead-code-finder.yaml; do
    [ -f "$yaml" ] || continue

    id=$(basename "$yaml" .yaml)
    sha=$(shasum -a 256 "$yaml" | cut -d ' ' -f1)

    # Extract metadata from YAML
    name=$(grep '^name:' "$yaml" | head -1 | sed 's/^name: *"//' | sed 's/"$//')
    desc=$(grep '^description:' "$yaml" | head -1 | sed 's/^description: *"//' | sed 's/"$//')

    # Get tags from YAML and format as JSON array
    tagline=$(grep '^tags:' "$yaml" | head -1)
    tags_json=$(echo "$tagline" | sed 's/^tags: *\[//' | sed 's/\]$//' | sed 's/, /, /g')

    [ $first -eq 1 ] || printf ',\n'
    first=0

    printf '    {\n'
    printf '      "id": "%s",\n' "$id"
    printf '      "name": "%s",\n' "$name"
    printf '      "description": "%s",\n' "$desc"
    printf '      "version": "1.0.0",\n'
    printf '      "author": { "name": "Overcli", "url": "https://github.com/overcodelions/overcli" },\n'
    printf '      "tags": [%s],\n' "$tags_json"
    printf '      "sha256": "%s",\n' "$sha"
    printf '      "yaml_url": "flows/%s.yaml"\n' "$id"
    printf '    }'
  done

  printf '\n  ]\n}\n'
} > index.json
