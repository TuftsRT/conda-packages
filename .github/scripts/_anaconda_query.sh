# shellcheck disable=SC2148

# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/_exit_failure.sh"

extract_local_metadata() {
  local repodata_file="$1"
  local context="$2"
  local entry_count

  entry_count="$(jq '."packages.conda" | length' "$repodata_file")"
  if [ "$entry_count" -ne 1 ]; then
    exit_failure \
      "$context: expected exactly one build in repodata but found $entry_count"
  fi

  jq -c 'first(."packages.conda"[])' "$repodata_file"
}

find_distinct_versions() {
  local files="$1"
  local label="$2"

  jq -r --arg label "$label" \
    '[.[] | select((.labels // []) | index($label)) | .version] | unique[]' \
    <<< "$files"
}

find_files_for_version() {
  local files="$1"
  local version="$2"
  local label="$3"
  local max_build="${4:-null}" # only list builds equal to or below this one
  local exclude="${5:-}"       # basename to exclude from results

  jq -r --arg version "$version" --arg label "$label" \
    --argjson max_build "$max_build" --arg exclude "$exclude" \
    '.[] | select(.version == $version and
      ((.labels // []) | index($label)) and
      ($max_build == null or .attrs.build_number <= $max_build) and
      ($exclude == "" or .basename != $exclude)) |
      [.version, .attrs.subdir, (.basename | split("/") | last)] | @tsv' \
    <<< "$files"
}

find_highest_build() {
  local files="$1"
  local version="$2"
  local label="$3"

  jq -c --arg version "$version" --arg label "$label" \
    '[.[] | select(.version == $version and
      ((.labels // []) | index($label)))] |
      sort_by(.attrs.build_number) | last' <<< "$files"
}

find_unlabeled_files() {
  jq -r \
    '.[] | select((.labels // []) == []) |
      [.version, .attrs.subdir, (.basename | split("/") | last)] | @tsv' \
    <<< "$1"
}

highest_build_across() {
  local files="$1"
  local version="$2"
  shift 2

  jq -r --arg version "$version" \
    '[.[] | select(.version == $version and
      ((.labels // []) | any(IN($ARGS.positional[])))) |
      .attrs.build_number] | max // -1' --args "$@" <<< "$files"
}

highest_version_across() {
  local files="$1"
  shift

  jq -r \
    '[.[] | select((.labels // []) | any(IN($ARGS.positional[]))) |
      .version] | unique[]' --args "$@" <<< "$files" | sort -V | tail -n1
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

load_local_metadata() {
  local package="$1"
  local repodata_file="output/win-64/repodata.json"

  if [ ! -f "$repodata_file" ]; then
    exit_failure "$package: $repodata_file not found"
  fi

  extract_local_metadata "$repodata_file" "$package"
}

assert_dev_promotable() {
  local files="$1"
  local package="$2"
  local version="$3"
  local build="$4"
  local highest_version highest_build

  highest_version="$(highest_version_across "$files" dev main)"

  if [ -n "$highest_version" ] && version_lt "$version" "$highest_version"
  then
    exit_failure "$package: $version is older than $highest_version"
  elif [ "$version" = "$highest_version" ]; then
    highest_build="$(highest_build_across "$files" "$version" dev main)"
    if [ "$build" -lt "$highest_build" ]; then
      exit_failure \
        "$package: build $build must not regress below $highest_build"
    fi
  fi
}

assert_main_promotable() {
  local files="$1"
  local package="$2"
  local version="$3"
  local build="$4"
  local highest_version highest_build

  highest_version="$(highest_version_across "$files" main)"

  if [ -n "$highest_version" ] && version_lt "$version" "$highest_version"
  then
    exit_failure "$package: $version is older than $highest_version"
  elif [ "$version" = "$highest_version" ]; then
    highest_build="$(highest_build_across "$files" "$version" main)"
    if [ "$build" -le "$highest_build" ]; then
      exit_failure "$package: build $build must exceed $highest_build"
    fi
  fi
}
