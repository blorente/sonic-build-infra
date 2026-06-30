#!/bin/bash
#
# Splits one ELF into a stripped binary plus a build-id-named .debug file,
# mirroring Debian's dh_strip. Invoked by the strip_binary rule.
#
# Args (all positional):
#   1  input ELF (read-only)
#   2  stripped binary output path
#   3  debug output directory (a TreeArtifact); the .debug file is written inside
#   4  objcopy from the toolchain
#   5  readelf from the toolchain
set -euo pipefail

input="$1"
stripped_out="$2"
debug_dir="$3"
objcopy="$4"
readelf="$5"

# objcopy rewrites in place, so work on a writable copy kept inside the action's
# output tree (the input and /tmp may be read-only under sandboxing).
tmp="${stripped_out}.input_copy.tmp"
cp "$input" "$tmp"

# The .debug file is named by the binary's build-id; that is how gdb re-finds it
# via the .gnu_debuglink. The build-id is only known here, at action time.
build_id="$("$readelf" -n "$tmp" | awk '/Build ID:/ { print $NF }')"
if [[ -z "$build_id" ]]; then
  echo "ERROR: input binary '$input' has no build-id; cannot name the debug file" >&2
  rm -f "$tmp"
  exit 1
fi

mkdir -p "$debug_dir"
debug_file="${debug_dir}/${build_id}.debug"

# Extract the debug info into the build-id-named file.
"$objcopy" --only-keep-debug "$tmp" "$debug_file"

# Strip the debug info from the binary and point it back at the debug file.
# objcopy records only the basename in the .gnu_debuglink.
"$objcopy" --strip-debug --add-gnu-debuglink="$debug_file" "$tmp" "$stripped_out"

rm -f "$tmp"
