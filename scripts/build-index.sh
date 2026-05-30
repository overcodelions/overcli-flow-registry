#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

# Build index.json from flows
{
  printf '{\n  "flows": [\n'
  first=1

  for yaml in flows/*.yaml; do
    [ -f "$yaml" ] || continue

    id=$(basename "$yaml" .yaml)
    sha=$(shasum -a 256 "$yaml" | cut -d ' ' -f1)

    # Extract name/description: strip leading "key: ", optional surrounding quotes, trailing quote
    name=$(grep '^name:' "$yaml" | head -1 | sed -E 's/^name:[[:space:]]*//; s/^"//; s/"$//')
    desc=$(grep '^description:' "$yaml" | head -1 | sed -E 's/^description:[[:space:]]*//; s/^"//; s/"$//')
    # Escape backslashes and double quotes for JSON
    name_json=$(printf '%s' "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
    desc_json=$(printf '%s' "$desc" | sed 's/\\/\\\\/g; s/"/\\"/g')

    # Tags: pull the [..] list, split on commas, quote each item
    tagline=$(grep '^tags:' "$yaml" | head -1 || true)
    tags_json=""
    if [ -n "$tagline" ]; then
      raw=$(printf '%s' "$tagline" | sed -E 's/^tags:[[:space:]]*\[//; s/\][[:space:]]*$//')
      IFS=','
      sep=""
      for t in $raw; do
        t=$(printf '%s' "$t" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^"//; s/"$//')
        [ -z "$t" ] && continue
        tags_json="${tags_json}${sep}\"${t}\""
        sep=", "
      done
      unset IFS
    fi

    [ $first -eq 1 ] || printf ',\n'
    first=0

    printf '    {\n'
    printf '      "id": "%s",\n' "$id"
    printf '      "name": "%s",\n' "$name_json"
    printf '      "description": "%s",\n' "$desc_json"
    printf '      "version": "1.0.0",\n'
    printf '      "author": { "name": "Overcli", "url": "https://github.com/overcodelions/overcli" },\n'
    printf '      "tags": [%s],\n' "$tags_json"
    printf '      "sha256": "%s",\n' "$sha"
    printf '      "yaml_url": "flows/%s.yaml"\n' "$id"
    printf '    }'
  done

  printf '\n  ]\n}\n'
} > index.json
