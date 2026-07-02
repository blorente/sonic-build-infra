#!/usr/bin/env bash
set -euo pipefail

objdump="${OBJDUMP:?"OBJDUMP must be set"}"
readelf="${READELF:?"READELF must be set"}"
binary_under_test="${BINARY_UNDER_TEST:?"BINARY_UNDER_TEST must be set"}"
debug_dir="${DEBUG_DIR:?"DEBUG_DIR must be set"}"

fail() { echo "ASSERT FAILED: $*" >&2; exit 1; }

find_debug_file() {
  # The debug file lives at .build-id/NN/REST.debug
  find -L "$debug_dir" -type f -name '*.debug'
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

assert_debug_file_at_build_id_path() {
  # dh_strip puts the debug file at .build-id/NN/REST.debug
  local debug_file
  local build_id
  local debug_file_relative
  local expected
  debug_file="$(find_debug_file)"
  build_id="$("$readelf" -n "$binary_under_test" 2>/dev/null | awk '/Build ID:/ { print $NF }')"
  if [[ -z "$build_id" ]]; then
    fail "could not read build-id from stripped binary"
  fi
  debug_file_relative="${debug_file#"$debug_dir"/}"
  expected=".build-id/${build_id:0:2}/${build_id:2}.debug"
  if [[ "$debug_file_relative" != "$expected" ]]; then
    fail "debug file at '$debug_file_relative', expected '$expected'"
  fi
}

run_test() {
  test_cmd="${1}"
  echo "Testing ${test_cmd} ..."
  "${test_cmd}"
  echo "  OK"
}

run_test assert_stripped_bin_has_no_debug_sections
run_test assert_stripped_binary_has_gnu_debug_link
run_test assert_debug_dir_has_only_one_file
run_test assert_debug_file_has_debug_sections
run_test assert_debug_file_at_build_id_path

echo OK
