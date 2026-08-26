#!/usr/bin/env bash

set -euo pipefail

: "${GITHUB_OUTPUT:?}"
: "${PR_BASE_SHA:?}"
: "${PR_HEAD_SHA:?}"

filter_recipe_dirs() {
  while read -r dir; do
    [ -n "$dir" ] &&
      git cat-file -e "$PR_HEAD_SHA:$dir/recipe.yaml" 2>/dev/null &&
      echo "$dir"
  done
}

git fetch origin "$PR_BASE_SHA" "$PR_HEAD_SHA"

merge_base="$(git merge-base "$PR_BASE_SHA" "$PR_HEAD_SHA")"

changed="$(git diff --name-only "$merge_base" "$PR_HEAD_SHA" |
  cut -d/ -f1 |
  sort -u |
  filter_recipe_dirs)"

if [ -z "$changed" ]; then
  matrix="[]"
  has_changes="false"
else
  matrix="$(jq -n -c --arg changed "$changed" '$changed | split("\n")')"
  has_changes="true"
fi

{
  echo "matrix=$matrix"
  echo "has-changes=$has_changes"
} >> "$GITHUB_OUTPUT"
