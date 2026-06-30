"""Assertion macro that verifies a strip_binary target stripped its input correctly.
"""

def _assert_stripped_test_impl(ctx):
    objdump = ctx.executable._objdump
    readelf = ctx.executable._readelf

    stripped = ctx.file.stripped
    debug = ctx.file.debug  # the build-id-named .debug TreeArtifact directory
    test_script = ctx.file._test_script

    # The script itself is the test executable; it reads its inputs from the
    # environment rather than argv. Symlink it into place under this rule's name.
    exe = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.symlink(output = exe, target_file = test_script, is_executable = True)

    runfiles = ctx.runfiles(files = [stripped, debug])
    runfiles = runfiles.merge(ctx.attr._objdump[DefaultInfo].default_runfiles)
    runfiles = runfiles.merge(ctx.attr._readelf[DefaultInfo].default_runfiles)

    # objdump and readelf are both passed explicitly from the toolchain's tools
    # package (readelf has no CcToolchainInfo field, so for consistency objdump
    # comes the same way). Paths are runfiles-relative: cwd at test time is the
    # runfiles root, and each tool's binary is brought in via its runfiles above.
    env = {
        "OBJDUMP": objdump.short_path,
        "READELF": readelf.short_path,
        "BINARY_UNDER_TEST": stripped.short_path,
        "DEBUG_DIR": debug.short_path,
    }
    return [
        DefaultInfo(executable = exe, runfiles = runfiles),
        RunEnvironmentInfo(environment = env),
    ]

_assert_stripped_test = rule(
    implementation = _assert_stripped_test_impl,
    test = True,
    attrs = {
        "stripped": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The 'stripped' output of the strip_binary target under test.",
        ),
        "debug": attr.label(
            mandatory = True,
            allow_single_file = True,
            doc = "The 'debug' output (a build-id-named .debug tree) under test.",
        ),
        "_test_script": attr.label(
            default = "//binary:test_stripped_binary.sh",
            allow_single_file = True,
            doc = "The shell script holding the actual assertions.",
        ),
        "_objdump": attr.label(
            default = "//toolchains/gcc/tools:objdump",
            executable = True,
            cfg = "exec",
            doc = "objdump from the toolchain, used to inspect ELF sections.",
        ),
        "_readelf": attr.label(
            default = "//toolchains/gcc/tools:readelf",
            executable = True,
            cfg = "exec",
            doc = "readelf from the toolchain, used to read the binary's build-id.",
        ),
    },
)
# TODO BL: Figure out how to get objdump and readelf from the cc toolchain.

def assert_stripped(name, strip_target, **kwargs):
    """Assert that `strip_target` (a strip_binary) stripped its input correctly.

    Args:
        name: name of the test target.
        strip_target: label of the strip_binary target to check.
        **kwargs: passed through to the underlying test (e.g. tags, timeout).
    """
    stripped = "{}_stripped".format(name)
    debug = "{}_debug".format(name)

    # Pull the two output groups of strip_binary out as addressable single files.
    native.filegroup(
        name = stripped,
        srcs = [strip_target],
        output_group = "stripped",
        testonly = True,
    )
    native.filegroup(
        name = debug,
        srcs = [strip_target],
        output_group = "debug",
        testonly = True,
    )

    _assert_stripped_test(
        name = name,
        stripped = stripped,
        debug = debug,
        **kwargs
    )
