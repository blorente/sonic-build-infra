"""Toolchain exposing useful binutils binaries, such as readelf, that are not exposed by the CC toolchain."""

BINUTILS_TOOLCHAIN_TYPE = "//toolchains/binutils:toolchain_type"

BinutilsInfo = provider(
    doc = "Paths to different binutils, such as readelf, for the execution platform. This exists because cc toolchains do not forward certain binutils tools.",
    fields = {
        "readelf": "FilesToRun provider to the readelf binary",
        "objcopy": "FilesToRun provider to the objcopy binary",
        "objdump": "FilesToRun provider to the objdump binary",
    },
)

def _binutils_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        binutils = BinutilsInfo(
            readelf = ctx.attr.readelf[DefaultInfo].files_to_run,
            objcopy = ctx.attr.objcopy[DefaultInfo].files_to_run,
            objdump = ctx.attr.objdump[DefaultInfo].files_to_run,
        ),
    )
    return [
        toolchain_info,
    ]

binutils_toolchain = rule(
    implementation = _binutils_toolchain_impl,
    doc = "Expose useful binutils as a toolchain",
    attrs = {
        "readelf": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "objcopy": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
        "objdump": attr.label(
            mandatory = True,
            executable = True,
            cfg = "exec",
            allow_single_file = True,
        ),
    },
)
