# shellcheck disable=SC2148

exit_failure() {
  echo "::error::$1" >&2
  exit 1
}
