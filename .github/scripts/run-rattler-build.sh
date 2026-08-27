#!/usr/bin/env bash

set -euo pipefail

: "${CI_TAG:?}"
: "${GITHUB_STEP_SUMMARY:?}"
: "${RECIPE_PATH:?}"

: "${RATTLER_BUILD_ENABLE_GITHUB_INTEGRATION:=true}"

if [ "$RATTLER_BUILD_ENABLE_GITHUB_INTEGRATION" = true ]; then
  {
    echo "<details>"
    echo "<summary>Build details</summary>"
    echo
  } >> "$GITHUB_STEP_SUMMARY"

  trap '{ echo; echo "</details>"; echo; } >> "$GITHUB_STEP_SUMMARY"' EXIT
fi

export RATTLER_BUILD_ENABLE_GITHUB_INTEGRATION

rattler-build build \
  --build-platform win-64 \
  --color always \
  --log-style simple \
  --package-format conda \
  --recipe "$RECIPE_PATH"
