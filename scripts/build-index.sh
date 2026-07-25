#!/usr/bin/env bash
# Regenerate index.json from flows/*.yaml, validating each flow's metadata
# on the way through. Run after adding or editing any flow:
#
#   bash scripts/build-index.sh
#
# The sha256 of each YAML is what `overcli/src/main/flows/registry.ts`
# checks on install, so a stale index is a hard install failure — never
# hand-edit index.json.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail=0
err() { printf 'error: %s\n' "$1" >&2; fail=1; }

# Tag vocabulary comes from TAGS.md so the doc stays the single source of
# truth. Each `## Heading` starts an axis; the lines under it are the
# comma-separated tags for that axis.
axis_tags() {
  awk -v want="$1" '
    /^## / { axis = tolower($2); next }
    axis == want && NF { print }
  ' TAGS.md | tr ',' '\n' | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' | grep -v '^$'
}
ACTIVITY_TAGS="$(axis_tags activity)"
SURFACE_TAGS="$(axis_tags surface)"
DOMAIN_TAGS="$(axis_tags domain)"
BACKEND_TAGS="$(axis_tags backend)"
ALL_TAGS="$(printf '%s\n%s\n%s\n%s\n' "$ACTIVITY_TAGS" "$SURFACE_TAGS" "$DOMAIN_TAGS" "$BACKEND_TAGS")"

has_tag() { printf '%s\n' "$2" | grep -qx "$1"; }

# Pull `key: value` off a top-level YAML line, stripping optional quotes.
scalar() { grep "^$2:" "$1" | head -1 | sed -E "s/^$2:[[:space:]]*//; s/^\"//; s/\"$//"; }
json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }

{
  printf '{\n  "flows": [\n'
  first=1

  for yaml in flows/*.yaml; do
    [ -f "$yaml" ] || continue

    id=$(basename "$yaml" .yaml)
    sha=$(shasum -a 256 "$yaml" | cut -d ' ' -f1)

    name=$(scalar "$yaml" name)
    desc=$(scalar "$yaml" description)
    version=$(scalar "$yaml" version)

    [ -n "$name" ] || err "$yaml: missing 'name'"
    [ -n "$desc" ] || err "$yaml: missing 'description'"
    # Version drives the registry's (id, version) install key — a flow that
    # ships a change without bumping it is indistinguishable from the old one.
    if [ -z "$version" ]; then
      err "$yaml: missing 'version' (e.g. 1.0.0)"
      version="0.0.0"
    elif ! printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$'; then
      err "$yaml: version '$version' is not MAJOR.MINOR.PATCH"
    fi

    # author: { name: "…", url: "…" } — a single-line YAML flow map.
    authorline=$(grep '^author:' "$yaml" | head -1 || true)
    if [ -z "$authorline" ]; then
      err "$yaml: missing 'author'"
      author_name=""; author_url=""
    else
      author_name=$(printf '%s' "$authorline" | sed -E 's/.*name:[[:space:]]*"([^"]*)".*/\1/')
      author_url=$(printf '%s' "$authorline" | sed -E 's/.*url:[[:space:]]*"([^"]*)".*/\1/')
    fi

    # Tags: pull the [..] list, split on commas, quote each item.
    tagline=$(grep '^tags:' "$yaml" | head -1 || true)
    tags_json=""
    tags_list=""
    if [ -n "$tagline" ]; then
      raw=$(printf '%s' "$tagline" | sed -E 's/^tags:[[:space:]]*\[//; s/\][[:space:]]*$//')
      IFS=','
      sep=""
      for t in $raw; do
        t=$(printf '%s' "$t" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^"//; s/"$//')
        [ -z "$t" ] && continue
        tags_json="${tags_json}${sep}\"${t}\""
        tags_list="${tags_list}${t}
"
        sep=", "
      done
      unset IFS
    fi

    tag_count=$(printf '%s' "$tags_list" | grep -c . || true)
    if [ "$tag_count" -lt 3 ] || [ "$tag_count" -gt 6 ]; then
      err "$yaml: has $tag_count tags, expected 3-6"
    fi
    while read -r t; do
      [ -z "$t" ] && continue
      has_tag "$t" "$ALL_TAGS" || err "$yaml: tag '$t' is not in TAGS.md"
    done <<EOF
$tags_list
EOF
    for axis in activity:"$ACTIVITY_TAGS" surface:"$SURFACE_TAGS" backend:"$BACKEND_TAGS"; do
      axis_name=${axis%%:*}
      axis_vocab=${axis#*:}
      found=0
      while read -r t; do
        [ -z "$t" ] && continue
        if has_tag "$t" "$axis_vocab"; then found=1; break; fi
      done <<EOF
$tags_list
EOF
      [ "$found" -eq 1 ] || err "$yaml: no '$axis_name' tag"
    done

    [ $first -eq 1 ] || printf ',\n'
    first=0

    printf '    {\n'
    printf '      "id": "%s",\n' "$id"
    printf '      "name": "%s",\n' "$(json_escape "$name")"
    printf '      "description": "%s",\n' "$(json_escape "$desc")"
    printf '      "version": "%s",\n' "$version"
    printf '      "author": { "name": "%s", "url": "%s" },\n' \
      "$(json_escape "$author_name")" "$(json_escape "$author_url")"
    printf '      "tags": [%s],\n' "$tags_json"
    printf '      "sha256": "%s",\n' "$sha"
    printf '      "yaml_url": "flows/%s.yaml"\n' "$id"
    printf '    }'
  done

  printf '\n  ]\n}\n'
} > index.json.tmp

if [ "$fail" -ne 0 ]; then
  rm -f index.json.tmp
  printf '\nindex.json NOT written — fix the errors above.\n' >&2
  exit 1
fi

mv index.json.tmp index.json
printf 'index.json written (%s flows)\n' "$(ls flows/*.yaml | wc -l | tr -d ' ')"
