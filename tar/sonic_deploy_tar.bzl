"""Rule to wrap tar(), which ensures binaries are stripped, and creates tars with debug symbols"""

load("@bazel_lib//lib:copy_to_directory.bzl", "copy_to_directory")
load("@bazel_lib//lib:utils.bzl", "propagate_common_rule_attributes")
load("@tar.bzl//tar:mtree.bzl", "mutate")
load("@tar.bzl//tar:tar.bzl", "tar", "tar_rule")
load("//binary:strip_binary.bzl", "strip_binary")

def _sonic_deploy_tar_impl(name, force_debug_build, binaries = {}, srcs = [], mtree = [], **kwargs):
    # We strip each binary and generate its mtree line pointing at the stripped ELF
    stripped_targets = []
    debug_targets = []
    binary_mtree = []
    for mtree_prefix, binary in binaries.items():
        stripped_name = "{}_{}_stripped".format(name, binary.name)
        strip_binary(
            name = stripped_name,
            src = binary,
            force_debug_build = force_debug_build,
            **propagate_common_rule_attributes(kwargs)
        )

        # Pick apart the stripped binary and debug symbols
        stripped_file = stripped_name + "_file"
        native.filegroup(
            name = stripped_file,
            srcs = [":" + stripped_name],
            output_group = "stripped",
        )
        stripped_targets.append(":" + stripped_file)
        binary_mtree.append("{} content=$(location :{})".format(mtree_prefix, stripped_file))

        # strip_binary already lays the debug info out as .build-id/NN/REST.debug.
        debug_file = stripped_name + "_debug"
        native.filegroup(
            name = debug_file,
            srcs = [":" + stripped_name],
            output_group = "debug",
        )
        debug_targets.append(":" + debug_file)

    tar(
        name = name,
        srcs = srcs + stripped_targets,
        mtree = mtree + binary_mtree,
        **kwargs
    )

    # A second archive with ONLY the debug symbols,
    # laid out as /usr/lib/debug/.build-id/NN/REST.debug
    # for each binary, following GDB conventions.
    #
    # Should be loadable as an OCI container layer directly.
    debug_symbols = "{}_debug_symbols".format(name)
    copy_to_directory(
        name = debug_symbols,
        srcs = debug_targets,
        # Strip the per-target path, and leave just the `.build-id/NN/REST.debug` part.
        replace_prefixes = {"**/.build-id": ".build-id"},
    )
    tar(
        name = name + ".debug_symbols",
        srcs = [":" + debug_symbols],
        mutate = mutate(
            strip_prefix = native.package_name() + "/" + debug_symbols,
            package_dir = "./usr/lib/debug",
        ),
        visibility = kwargs["visibility"],
    )

sonic_deploy_tar = macro(
    implementation = _sonic_deploy_tar_impl,
    inherit_attrs = tar_rule,
    attrs = {
        "srcs": attr.label_list(
            default = [],
            allow_files = True,
            # We're referencing the srcs later in the mtree,
            # we can't make them configurable anyway.
            configurable = False,
        ),
        "mtree": attr.string_list(
            default = [],
            configurable = False,
        ),
        "binaries": attr.string_keyed_label_dict(
            doc = """Maps an mtree prefix (e.g. \"./usr/bin/foo uid=0 gid=0 mode=0755 type=file\") to a binary target.
The binary will then be replaced with its stripped version behind the scenes.
""",
            default = {},
            configurable = False,
        ),
        "force_debug_build": attr.bool(
            doc = "Whether the binaries should be rebuilt with debug information before stripping. This will override Bazel's regular CLI compilation instructions, like `--strip=never`",
            default = False,
        ),
        # We do not allow mutate for now, as we rely on messing with the mtree.
        "mutate": None,
    },
)
