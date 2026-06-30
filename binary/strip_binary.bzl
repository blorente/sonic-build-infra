"""Rule that splits a compiled binary into its stripped form and its debug symbols.

Behaviour mirrors Debian's dh_strip:
It is language-agnostic and operates on the ELF directly via binutils objcopy.
"""

def _strip_binary_impl(ctx):
    src = ctx.file.src
    stripped = ctx.actions.declare_file(ctx.attr.name + ".stripped")

    # The debug output is a TreeArtifact: its single entry is named by the
    # binary's build-id, which is only knowable at action time.
    #
    # TODO(bazel-ready): In Bazel 9, we may be able to use `map_directory` to surface
    # the debug info as a file output.
    #   Ref: https://bazel.build/rules/lib/builtins/actions#map_directory
    debug = ctx.actions.declare_directory(ctx.attr.name + ".debug")

    args = ctx.actions.args()
    args.add(src)
    args.add(stripped)
    args.add(debug.path)
    args.add(ctx.executable._objcopy)
    args.add(ctx.executable._readelf)

    ctx.actions.run(
        executable = ctx.file._strip_tool,
        arguments = [args],
        inputs = [src, ctx.file._strip_tool],
        outputs = [stripped, debug],
        tools = [
            ctx.attr._objcopy[DefaultInfo].files_to_run,
            ctx.attr._readelf[DefaultInfo].files_to_run,
        ],
        mnemonic = "StripBinary",
        progress_message = "Stripping debug info from %{label}",
    )

    return [
        DefaultInfo(files = depset([stripped, debug])),
        OutputGroupInfo(
            stripped = depset([stripped]),
            debug = depset([debug]),
        ),
    ]

strip_binary = rule(
    implementation = _strip_binary_impl,
    doc = "Takes a single compiled ELF target and produces (a) a stripped version with debug " +
          "info removed, and (b) the extracted debug symbols as a <build-id>.debug file. ",
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_single_file = True,
            cfg = "target",
            doc = "The compiled ELF target to strip: an executable, shared library, or " +
                  "static library.",
        ),
        "_strip_tool": attr.label(
            default = "//binary:strip_binary.sh",
            allow_single_file = True,
            cfg = "exec",
            doc = "The script that drives objcopy to split the ELF.",
        ),
        "_objcopy": attr.label(
            default = "//toolchains/gcc/tools:objcopy",
            executable = True,
            cfg = "exec",
            doc = "objcopy from the toolchain, used to extract/strip debug info.",
        ),
        "_readelf": attr.label(
            default = "//toolchains/gcc/tools:readelf",
            executable = True,
            cfg = "exec",
            doc = "readelf from the toolchain, used to read the binary's build-id.",
        ),
    },
)

# TODO BL: Figure out how to get objcopy and readelf from the cc toolchain.
