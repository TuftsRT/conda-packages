# shellcheck disable=SC2148

# shellcheck disable=SC1091
source "$(dirname "$0")/_exit_failure.sh"

extract_local_metadata() {
  local repodata_file="$1"
  local context="$2"
  local package_entries entry_count

  package_entries="$(jq -c '."packages.conda" | to_entries' "$repodata_file")"
  entry_count="$(jq 'length' <<< "$package_entries")"
  if [ "$entry_count" -ne 1 ]; then
    exit_failure \
      "$context: expected exactly one build in repodata but found $entry_count"
  fi

  jq -c '.[0].value' <<< "$package_entries"
}

find_distinct_versions() {
  local files="$1"
  local label="$2"

  jq -r --arg label "$label" \
    '[.[] | select((.labels // []) | index($label)) | .version] |
    unique[]' <<< "$files"
}

find_files_for_version() {
  local files="$1"
  local version="$2"
  local label="$3"
  local max_build="${4:-null}" # only list builds strictly below this one

  jq -r --arg version "$version" --arg label "$label" \
    --argjson max_build "$max_build" \
    '.[] | select(.version == $version and
      ((.labels // []) | index($label)) and
      ($max_build == null or .attrs.build < $max_build)) |
      [.version, .attrs.subdir, (.basename | split("/") | last)] | @tsv' \
    <<< "$files"
}

find_highest_build() {
  local files="$1"
  local version="$2"
  local label="$3"

  jq -c --arg version "$version" --arg label "$label" \
    '[.[] | select(.version == $version and
      ((.labels // []) | index($label)))] | sort_by(.attrs.build) | last' \
    <<< "$files"
}

find_orphaned_files() {
  local files="$1"
  local label="$2"

  jq -r --arg label "$label" \
    '.[] | select((.labels // []) == [$label]) |
    [.version, .attrs.subdir, (.basename | split("/") | last)] | @tsv' \
    <<< "$files"
}

require_labeled_file() {
  local files="$1"
  local label="$2"
  local context="$3"
  local file

  file="$(jq -c --arg label "$label" \
    '[.[] | select((.labels // []) | index($label))] |
    sort_by(.upload_time) | last' <<< "$files")"
  if [ "$file" = "null" ]; then
    exit_failure "$context: no build with label $label found"
  fi
  echo "$file"
}

require_package_files() {
  local owner="$1"
  local package="$2"
  local response status

  response="$(curl -sS -w '\n%{http_code}' \
    "https://api.anaconda.org/package/$owner/$package/files")"
  status="${response##*$'\n'}"

  case "$status" in
    200) echo "${response%$'\n'*}" ;;
    404) echo "[]" ;; # package has no files yet (never published)
    *) exit_failure "$package: failed to list package files" ;;
  esac
}

version_lt() {
  [ "$1" != "$2" ] &&
    [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

assert_build_advances() {
  local files="$1"
  local package="$2"
  local version="$3"
  local build="$4"
  local dev_build main_build highest_build

  dev_build="$(find_highest_build "$files" "$version" dev |
    jq -r '.attrs.build // -1')"
  main_build="$(find_highest_build "$files" "$version" main |
    jq -r '.attrs.build // -1')"
  highest_build=$(( dev_build > main_build ? dev_build : main_build ))

  if [ "$build" -le "$highest_build" ]; then
    exit_failure "$package: build $build must exceed $highest_build"
  fi
}

assert_sequential_version() {
  local files="$1"
  local package="$2"
  local version="$3"
  local current_highest

  current_highest="$(find_distinct_versions "$files" main |
    sort -V | tail -n1)"
  if [ -n "$current_highest" ] && [ "$version" != "$current_highest" ] &&
    version_lt "$version" "$current_highest"
  then
    exit_failure "$package: $version is older than $current_highest on main"
  fi
}
