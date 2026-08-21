#!/usr/bin/env bash
set -euo pipefail

readelf="${READELF:?"READELF must be set"}"
library_under_test="${LIBRARY_UNDER_TEST:?"LIBRARY_UNDER_TEST must be set"}"

fail() { echo "ASSERT FAILED: $*" >&2; exit 1; }

assert_is_shared_object() {
  local type
  type="$("$readelf" --file-header "$library_under_test" | awk -F: '/^ *Type:/ {print $2}')"
  if [[ "$type" != *DYN* ]]; then
    fail "expected an ELF DYN (shared object), got '${type# }'"
  fi
}

assert_no_text_relocations() {
  if "$readelf" --dynamic "$library_under_test" | grep -q TEXTREL; then
    fail "shared object has text relocations (TEXTREL): built from non-PIC objects"
  fi
}

run_test() {
  test_cmd="${1}"
  echo "Testing ${test_cmd} ..."
  "${test_cmd}"
  echo "  OK"
}

run_test assert_is_shared_object
run_test assert_no_text_relocations

echo OK
