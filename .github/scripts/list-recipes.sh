#!/usr/bin/env bash

set -euo pipefail

: "${GITHUB_OUTPUT:?}"

recipes="$(
  for dir in */; do
    package="${dir%/}"
    [ -f "$package/recipe.yaml" ] && echo "$package" || true
  done
)"

if [ -z "$recipes" ]; then
  matrix="[]"
else
  matrix="$(jq -n -c --arg recipes "$recipes" '$recipes | split("\n")')"
fi

echo "matrix=$matrix" >> "$GITHUB_OUTPUT"
