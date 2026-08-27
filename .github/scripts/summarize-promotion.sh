#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_OWNER:?}"
: "${CHANNEL:?}"
: "${GITHUB_STEP_SUMMARY:?}"
: "${PACKAGE:?}"
: "${VERSION:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_print_utils.sh"

metadata="$(build_metadata "$ANACONDA_OWNER" "$CHANNEL" "$PACKAGE" "$VERSION")"

if [ -n "${METADATA_FILE:-}" ]; then
  printf '%s\n' "$metadata" > "$METADATA_FILE"
fi

code_block "$(match_spec "$metadata")" >> "$GITHUB_STEP_SUMMARY"
