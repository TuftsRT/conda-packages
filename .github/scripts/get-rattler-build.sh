#!/usr/bin/env bash

set -euo pipefail

: "${RATTLER_BUILD_DIR:?}"
: "${RATTLER_BUILD_VERSION:?}"

: "${MAX_RETRIES:=3}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_exit_failure.sh"

mkdir -p "$RATTLER_BUILD_DIR"

url="https://github.com/prefix-dev/rattler-build/releases/download"
url="$url/$RATTLER_BUILD_VERSION/rattler-build-x86_64-pc-windows-msvc.exe"
exe="$RATTLER_BUILD_DIR/rattler-build.exe"

curl_args=(-sSLf --retry "$MAX_RETRIES" --retry-all-errors)
attempts=$((MAX_RETRIES + 1))
context="get-rattler-build"

for ((attempt = 1; attempt <= attempts; attempt++)); do
  curl "${curl_args[@]}" "$url" -o "$exe"

  expected="$(curl "${curl_args[@]}" "$url.sha256" | cut -d' ' -f1)"
  actual="$(sha256sum "$exe" | cut -d' ' -f1 | sed 's/^\\//')"

  if [ "$actual" = "$expected" ]; then
    chmod +x "$exe"
    exit 0
  fi

  {
    echo "::warning::$context: checksum mismatch on attempt $attempt/$attempts"
    echo "expected: $expected"
    echo "actual:   $actual"
  } >&2
done

exit_failure "$context: checksum mismatch after $attempts attempts"
