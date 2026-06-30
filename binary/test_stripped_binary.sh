#!/usr/bin/env bash
#
# Inputs arrive via the environment (set by the assert_stripped test rule):
#   OBJDUMP            objdump from the toolchain
#   READELF            readelf from the toolchain
#   BINARY_UNDER_TEST  the stripped binary
#   DEBUG_DIR          the build-id-named .debug TreeArtifact directory
set -euo pipefail

objdump="${OBJDUMP:?"OBJDUMP must be set"}"
readelf="${READELF:?"READELF must be set"}"
binary_under_test="${BINARY_UNDER_TEST:?"BINARY_UNDER_TEST must be set"}"
debug_dir="${DEBUG_DIR:?"DEBUG_DIR must be set"}"

fail() { echo "ASSERT FAILED: $*" >&2; exit 1; }

find_debug_file() {
  find -L "$debug_dir" -maxdepth 1 -type f
}

assert_stripped_bin_has_no_debug_sections() {
  local debug_sections="$("$objdump" -h "$binary_under_test" | grep '[.]debug_')"
  if [[ -n "$debug_sections" ]]; then
    fail "stripped binary still contains .debug_* sections"
  fi
}

assert_stripped_binary_has_gnu_debug_link() {
  # This is the behaviour of `dh_strip`.
  local debug_file="$(find_debug_file)"
  local linkname="$(basename "$debug_file")"
  local debuglink="$("$readelf" -p .gnu_debuglink "$binary_under_test" 2>/dev/null | grep "$linkname")"
  if [[ -z "$debuglink" ]]; then
    fail "stripped binary has no .gnu_debuglink naming $linkname"
  fi
}


assert_debug_dir_has_only_one_file() {
  local count
  count="$(find_debug_file | wc -l)"
  if [[ "$count" -ne 1 ]]; then
    fail "expected exactly one debug file under $debug_dir, found $count"
  fi
}

assert_debug_file_has_debug_sections() {
  local debug_file="$(find_debug_file)"
  local debug_sections="$("$objdump" -h "$debug_file" | grep '[.]debug_')"
  if [[ -z "$debug_sections" ]]; then
    fail "debug file $debug_file has no .debug_* sections"
  fi
}

assert_debug_file_name_is_build_id() {
  local debug_file="$(find_debug_file)"
  local linkname="$(basename "$debug_file")"
  local build_id="$("$readelf" -n "$binary_under_test" 2>/dev/null | awk '/Build ID:/ { print $NF }')"
  if [[ -z "$build_id" ]]; then
    fail "could not read build-id from stripped binary"
  fi
  if [[ "$linkname" != "$build_id.debug" ]]; then
    fail "debug file named '$linkname', expected '$build_id.debug'"
  fi
}

assert_stripped_bin_has_no_debug_sections
assert_stripped_binary_has_gnu_debug_link
assert_debug_dir_has_only_one_file
assert_debug_file_has_debug_sections
assert_debug_file_name_is_build_id

echo OK
