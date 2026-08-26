#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_OWNER:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_query.sh"

rows="$(
  for dir in */; do
    package="${dir%/}"
    [ -f "$package/recipe.yaml" ] || continue

    files="$(require_package_files "$ANACONDA_OWNER" "$package")"
    versions="$(find_distinct_versions "$files" dev)"
    [ -n "$versions" ] || continue

    while IFS= read -r version; do
      build="$(find_highest_build "$files" "$version" dev |
        jq -r '.attrs.build')"
      # shellcheck disable=SC2016
      printf '| `%s` | `%s` | `%s` |\n' "$package" "$version" "$build"
    done <<< "$versions"
  done
)"

if [ -z "$rows" ]; then
  echo "No development builds found."
else
  printf '| Package | Version | Build |\n'
  printf '|---|---|---|\n'
  echo "$rows"
fi
