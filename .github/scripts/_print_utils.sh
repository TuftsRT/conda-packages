# shellcheck disable=SC2148

augment_metadata() {
  local metadata="$1" owner="$2" channel="$3"

  jq --arg owner "$owner" --arg channel "$channel" \
    '. + {owner: $owner, channel: $channel}' <<< "$metadata"
}

build_metadata() {
  local owner="$1" channel="$2" name="$3" version="$4"

  jq -n --arg owner "$owner" --arg channel "$channel" \
    --arg name "$name" --arg version "$version" \
    '{owner: $owner, channel: $channel, name: $name, version: $version}'
}

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
