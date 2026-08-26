# shellcheck disable=SC2148

code_block() {
  echo '```'
  printf '%s\n' "$1"
  echo '```'
}

match_spec() {
  local metadata="$1"
  local owner channel name version

  owner="$(jq -r '.owner' <<< "$metadata")"
  channel="$(jq -r '.channel' <<< "$metadata")"
  name="$(jq -r '.name' <<< "$metadata")"
  version="$(jq -r '.version' <<< "$metadata")"

  printf '%s/label/%s::%s=%s' "$owner" "$channel" "$name" "$version"
}
