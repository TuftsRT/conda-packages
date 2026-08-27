# shellcheck disable=SC2148

branch_slug() {
  local branch="$1"
  local sanitized hash

  sanitized="$(
    printf '%s' "$branch" |
    tr -c 'A-Za-z0-9' '-' |
    tr -s '-' |
    sed 's/^-\|-$//'
  )"
  hash="$(printf '%s' "$branch" | sha256sum | cut -c1-4)"
  printf '%s-%s' "$sanitized" "$hash"
}
