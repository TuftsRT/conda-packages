#!/usr/bin/env bash

set -euo pipefail

: "${RATTLER_BUILD_DIR:?}"
: "${RATTLER_BUILD_VERSION:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_exit_failure.sh"

mkdir -p "$RATTLER_BUILD_DIR"

url="https://github.com/prefix-dev/rattler-build/releases/download"
url="$url/$RATTLER_BUILD_VERSION/rattler-build-x86_64-pc-windows-msvc.exe"
exe="$RATTLER_BUILD_DIR/rattler-build.exe"

curl -sSLf "$url" -o "$exe"

expected="$(curl -sSLf "$url.sha256" | cut -d' ' -f1)"
actual="$(sha256sum "$exe" | cut -d' ' -f1)"
if [ "$actual" != "$expected" ]; then
  exit_failure "rattler-build: checksum mismatch"
fi

chmod +x "$exe"
