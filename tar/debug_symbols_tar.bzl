"""Lay a set of debug-symbol trees into a tar under /usr/lib/debug.

Both 
 - `sonic_deploy_tar` (for a single tar's own binaries), and
 - `debug_symbols_layer` (for a whole image's graph)

need to turn `.build-id/NN/REST.debug` trees into a tar rooted at /usr/lib/debug.

Since it's finnicky, we extract the behaviour.
"""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@tar.bzl//tar:mtree.bzl", "mutate")
load("@tar.bzl//tar:tar.bzl", "tar")

def _join_package(path):
    pkg = native.package_name()
    return pkg + "/" + path if pkg else path

def _debug_symbols_tar_impl(name, visibility, srcs):
    # Normalize the per-target output paths down to a shared .build-id/... tree.
    # We're often gathering trees from different SONiC components,
    # which means different Bazel modules (`@sonic-sysmgr//...`).
    #
    # Therefore, we must remove the prefix of leading external repos
    symbols_dir = name + "_dir"
    copy_to_directory(
        name = symbols_dir,
        srcs = srcs,
        include_external_repositories = ["**"],
        replace_prefixes = {"**/.build-id": ".build-id"},
    )

    tar(
        name = name,
        srcs = [":" + symbols_dir],
        mutate = mutate(
            strip_prefix = _join_package(symbols_dir),
            package_dir = "./usr/lib/debug",
        ),
        visibility = visibility,
    )

debug_symbols_tar = macro(
    implementation = _debug_symbols_tar_impl,
    doc = "A tar of debug symbols laid out under /usr/lib/debug/.build-id.",
    attrs = {
        "srcs": attr.label_list(
            mandatory = True,
            allow_files = True,
            doc = "Targets producing `.build-id/NN/REST.debug` trees.",
        ),
    },
)
