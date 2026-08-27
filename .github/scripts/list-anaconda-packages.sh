#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_OWNER:?}"
: "${GITHUB_OUTPUT:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_exit_failure.sh"

response="$(curl -sS -w '\n%{http_code}' \
  "https://api.anaconda.org/packages/$ANACONDA_OWNER")"
status="${response##*$'\n'}"

if [ "$status" != "200" ]; then
  exit_failure \
    "anaconda.org/$ANACONDA_OWNER: failed to list packages (status $status)"
fi

matrix="$(jq -c '[.[].name]' <<< "${response%$'\n'*}")"

echo "matrix=$matrix" >> "$GITHUB_OUTPUT"
