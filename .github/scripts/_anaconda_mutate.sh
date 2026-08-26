# shellcheck disable=SC2148

# shellcheck disable=SC1091
source "$(dirname "$0")/_exit_failure.sh"

make_payload() {
  jq -n --arg package "$1" --arg version "$2" --arg basename "$3" \
    '{package: $package, version: $version, basename: $basename}'
}

status_in_list() {
  local status="$1"
  shift
  local expected

  for expected in "$@"; do
    if [ "$status" = "$expected" ]; then
      return 0
    fi
  done

  return 1
}

apply_label_operation() {
  local method="$1"
  local channel="$2"
  local context="$3"
  local owner="$4"
  local api_key="$5"
  local payload="$6"
  shift 6
  local expected_statuses=("$@")
  local status

  if [ "${#expected_statuses[@]}" -eq 0 ]; then
    expected_statuses=("200" "201")
  fi

  status="$(curl -sS -o /dev/null -w '%{http_code}' -X "$method" \
    "https://api.anaconda.org/channels/$owner/$channel" \
    -H "Authorization: token $api_key" \
    -H "Content-Type: application/json" \
    -d "$payload")"

  if ! status_in_list "$status" "${expected_statuses[@]}"; then
    exit_failure "$context: failed to $method $channel label (status $status)"
  fi
}

delete_dist_file() {
  local owner="$1"
  local api_key="$2"
  local package="$3"
  local version="$4"
  local platform="$5"
  local filename="$6"
  local strict="${7:-true}" # exit failure when deletion unsuccessful
  local dist_path="$package/$version/$platform/$filename"
  local status

  status="$(curl -sS -o /dev/null -w '%{http_code}' -X DELETE \
    "https://api.anaconda.org/dist/$owner/$dist_path" \
    -H "Authorization: token $api_key" || echo 000)"
  if ! status_in_list "$status" 200 201 404; then
    local msg="failed to delete $dist_path (status $status)"
    if "$strict"; then
      exit_failure "$msg"
    else
      echo "::warning::$msg" >&2
    fi
  fi
}

add_label() {
  local context="$1"
  local owner="$2"
  local api_key="$3"
  local channel="$4"
  local payload="$5"

  apply_label_operation \
    POST "$channel" "$context" "$owner" "$api_key" "$payload"
}

delete_label() {
  local context="$1"
  local owner="$2"
  local api_key="$3"
  local channel="$4"
  local payload="$5"
  shift 5

  apply_label_operation \
    DELETE "$channel" "$context" "$owner" "$api_key" "$payload" "$@"
}

sweep_stale_files() {
  local owner="$1"
  local api_key="$2"
  local package="$3"
  local tsv="$4"
  local strict="${5:-false}" # exit failure when any deletion unsuccessful

  [ -n "$tsv" ] || return 0

  while IFS=$'\t' read -r version platform filename; do
    delete_dist_file "$owner" "$api_key" "$package" \
      "$version" "$platform" "$filename" "$strict"
  done <<< "$tsv"
}
