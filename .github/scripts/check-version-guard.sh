#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_OWNER:?}"
: "${PACKAGE:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_query.sh"

local_metadata="$(load_local_metadata "$PACKAGE")"
local_version="$(jq -r '.version' <<< "$local_metadata")"
local_build="$(jq -r '.build_number' <<< "$local_metadata")"
local_build_string="$(jq -r '.build' <<< "$local_metadata")"

version_re='^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))?$'
if ! [[ "$local_version" =~ $version_re ]]; then
  exit_failure \
    "$PACKAGE: version $local_version must be MAJOR.MINOR or MAJOR.MINOR.PATCH"
fi

if [ -n "${CI_TAG:-}" ] && [[ "$local_build_string" != *"$CI_TAG"* ]]; then
  exit_failure \
    "$PACKAGE: build string $local_build_string is missing $CI_TAG"
fi

remote_metadata="$(require_package_files "$ANACONDA_OWNER" "$PACKAGE")"

assert_dev_promotable \
  "$remote_metadata" "$PACKAGE" "$local_version" "$local_build"
