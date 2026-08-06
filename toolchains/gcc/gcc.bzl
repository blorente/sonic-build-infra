"""Fetches a GCC distribution and overlays BUILD files on top
"""

GCC_VERSION = "12.5.0"

# The GCC Debian built its libraries with, which may or may not be the same.
# Its paths only carry the major, e.g. /usr/lib/gcc/x86_64-linux-gnu/12.
# We need this as long as we fetch the sysroot from Debian archives.
DEBIAN_GCC_MAJOR = "12"

# The CPU goes by different names in different places.
# This dict captures those differences.
#
# gcc:       the gcc prefix for the arch, e.g. x86_64-linux.
# deb:       the Debian package architecture, e.g. libc6_2.36-9_amd64.deb.
# multiarch: the Debian multiarch triple, e.g. /usr/lib/x86_64-linux-gnu.
GCC_METADATA = {
    "x86_64": struct(
        gcc = "x86_64-linux",
        deb = "amd64",
        multiarch = "x86_64-linux-gnu",
        dynamic_linker = "lib64/ld-linux-x86-64.so.2",
    ),
    "aarch64": struct(
        gcc = "aarch64-linux",
        deb = "arm64",
        multiarch = "aarch64-linux-gnu",
        dynamic_linker = "lib/ld-linux-aarch64.so.1",
    ),
}

GCC = """#!/bin/bash

args=("$@")

EXECROOT="${EXECROOT:-"$(realpath "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../../..")"}"

for i in "${!args[@]}"; do
    val="${args[i]}"

    # Make --sysroot flag absolute for GCC.
    if [[ "${val}" == "--sysroot="* ]]; then
        if [[ "${val}" == "--sysroot=/"* ]]; then
            # The path already seems to be absolute.
            continue
        fi
       # args["${i}"]="--sysroot=$(pwd)/${val#--sysroot=}"
    fi
done

exec "${EXECROOT}/${0%%-wrapped}" "${args[@]}"
"""

def _download_gcc(rctx):
    rctx.download_and_extract(
        url = rctx.attr.urls,
        integrity = rctx.attr.integrity,
    )
    target_arch = rctx.attr.target_arch
    rctx.delete("sysroot")

    rctx.template(
        "BUILD.bazel",
        rctx.attr.build_file_template,
        substitutions = {
            "{target_arch}": target_arch,
            "{version}": rctx.attr.version,
        },
        executable = False,
    )
    gcc_prefix = GCC_METADATA[target_arch].gcc
    rctx.file("bin/{}-gcc-wrapped".format(gcc_prefix), GCC, executable = True)
    rctx.file("bin/{}-g++-wrapped".format(gcc_prefix), GCC, executable = True)

fetch_gcc = repository_rule(
    implementation = _download_gcc,
    attrs = {
        "urls": attr.string_list(),
        "integrity": attr.string(),
        "target_arch": attr.string(
            default = "x86_64",
            values = ["x86_64", "aarch64"],
        ),
        "version": attr.string(mandatory = True),
        "build_file_template": attr.label(default = "//toolchains/gcc:gcc.BUILD"),
    },
)
