#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_OWNER:?}"
: "${CHANNEL:?}"
: "${GITHUB_STEP_SUMMARY:?}"
: "${PACKAGE:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_query.sh"

# shellcheck disable=SC1091
source "$(dirname "$0")/_print_utils.sh"

local_metadata="$(load_local_metadata "$PACKAGE")"
metadata="$(normalize_metadata "$local_metadata" "$ANACONDA_OWNER" "$CHANNEL")"

if [ -n "${METADATA_FILE:-}" ]; then
  printf '%s\n' "$metadata" > "$METADATA_FILE"
fi

{
  code_block "$(match_spec "$metadata")"
  echo
  printf '<%s>\n' "$(package_url "$metadata")"
} >> "$GITHUB_STEP_SUMMARY"
