# shellcheck disable=SC2148

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
  jq -j '"\(.owner)/label/\(.channel)::\(.name)=\(.version)"' <<< "$1"
}

normalize_metadata() {
  local metadata="$1" owner="$2" channel="$3"

  jq --arg owner "$owner" --arg channel "$channel" \
    '{owner: $owner, channel: $channel,
      name: .name, version: .version}' <<< "$metadata"
}
