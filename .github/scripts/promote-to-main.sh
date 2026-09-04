#!/usr/bin/env bash

set -euo pipefail

: "${ANACONDA_API_KEY:?}"
: "${ANACONDA_OWNER:?}"
: "${PACKAGE:?}"
: "${VERSION:?}"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_query.sh"

# shellcheck disable=SC1091
source "$(dirname "$0")/_anaconda_mutate.sh"

files="$(require_package_files "$ANACONDA_OWNER" "$PACKAGE")"

dev_file="$(find_highest_build "$files" "$VERSION" dev)"

if [ "$dev_file" = "null" ]; then
  exit_failure "$PACKAGE: no build for version $VERSION on dev"
fi

dev_build="$(jq -r '.attrs.build_number' <<< "$dev_file")"
dev_build_string="$(jq -r '.attrs.build' <<< "$dev_file")"
basename="$(jq -r '.basename' <<< "$dev_file")"

assert_main_promotable "$files" "$PACKAGE" "$VERSION" "$dev_build"

commit_sha="${dev_build_string##*_}"
if ! git rev-parse --verify -q "${commit_sha}^{commit}" > /dev/null; then
  exit_failure \
    "$PACKAGE: cannot resolve commit $commit_sha from build $dev_build_string"
fi

payload="$(make_payload "$PACKAGE" "$VERSION" "$basename")"

add_label "$PACKAGE" "$ANACONDA_OWNER" "$ANACONDA_API_KEY" \
  main "$payload"

tag="$PACKAGE/$VERSION-$dev_build"
git tag "$tag" "$commit_sha"
git push origin "$tag"

delete_label "$PACKAGE" "$ANACONDA_OWNER" "$ANACONDA_API_KEY" \
  dev "$payload" 200 201 404

while IFS= read -r candidate; do
  if version_lt "$candidate" "$VERSION"; then
    sweep_stale_files "$ANACONDA_OWNER" "$ANACONDA_API_KEY" "$PACKAGE" \
      "$(find_files_for_version "$files" "$candidate" dev)"
  fi
done < <(find_distinct_versions "$files" dev)
