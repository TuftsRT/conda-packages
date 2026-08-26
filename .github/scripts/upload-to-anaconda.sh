#!/usr/bin/env bash

set -euo pipefail
shopt -s globstar nullglob

: "${ANACONDA_API_KEY:?}" # used by rattler-build
: "${ANACONDA_CHANNEL:?}"
: "${ANACONDA_OWNER:?}" # used by rattler-build

# shellcheck disable=SC1091
source "$(dirname "$0")/_exit_failure.sh"

packages=(output/**/*.conda)
if [ "${#packages[@]}" -eq 0 ]; then
  exit_failure "no build artifacts found"
fi

case "$ANACONDA_CHANNEL" in
  gh-*) export ANACONDA_FORCE=1 ;;
esac

rattler-build upload anaconda "${packages[@]}"
