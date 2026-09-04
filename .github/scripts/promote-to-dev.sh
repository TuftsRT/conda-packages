#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_API_KEY:?}"
: "${ANACONDA_OWNER:?}"
: "${GITHUB_OUTPUT:?}"
: "${PACKAGE:?}"
: "${PR_LABEL:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_query.sh"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_mutate.sh"

files="$(require_package_files "$ANACONDA_OWNER" "$PACKAGE")"

pr_file="$(require_labeled_file "$files" "$PR_LABEL" "$PACKAGE")"
pr_version="$(jq -r '.version' <<< "$pr_file")"
pr_basename="$(jq -r '.basename' <<< "$pr_file")"
pr_build_number="$(jq -r '.attrs.build_number' <<< "$pr_file")"

assert_dev_promotable "$files" "$PACKAGE" "$pr_version" "$pr_build_number"

echo "version=$pr_version" >> "$GITHUB_OUTPUT"

payload="$(make_payload "$PACKAGE" "$pr_version" "$pr_basename")"

add_label "$PACKAGE" "$ANACONDA_OWNER" "$ANACONDA_API_KEY" dev "$payload"

delete_label "$PACKAGE" "$ANACONDA_OWNER" "$ANACONDA_API_KEY" "$PR_LABEL" \
  "$payload" 200 201 404

stale="$(find_files_for_version \
  "$files" "$pr_version" dev "$pr_build_number" "$pr_basename")"
sweep_stale_files "$ANACONDA_OWNER" "$ANACONDA_API_KEY" "$PACKAGE" "$stale"
