#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_API_KEY:?}"
: "${ANACONDA_OWNER:?}"
: "${LABEL:?}"
: "${PACKAGE:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_query.sh"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_mutate.sh"

delete_label \
  "$PACKAGE" "$ANACONDA_OWNER" "$ANACONDA_API_KEY" "$LABEL" '{}' 200 201 404

files="$(require_package_files "$ANACONDA_OWNER" "$PACKAGE")"
orphans="$(find_unlabeled_files "$files")"

sweep_stale_files \
  "$ANACONDA_OWNER" "$ANACONDA_API_KEY" "$PACKAGE" "$orphans" true
