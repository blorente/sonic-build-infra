"""Macro for declaring SONiC's binutils toolchains.
"""

load("//toolchains/gcc:defs.bzl", "bin")
load(":binutils_toolchain.bzl", "binutils_toolchain")

def sonic_binutils_toolchain(name, cpu, version, visibility = None):
    """Declares a binutils toolchain where `exec == target == $cpu`.

    Args:
        name: Name of the `toolchain()` target.
        cpu: The `@platforms//cpu` value this toolchain both runs on and targets, e.g. `x86_64`.
        version: The GCC version whose distribution the tools come from, e.g. `14.2.0`.
                 With `cpu` it names the `gcc.debian_toolchain()` tag that fetched it.
        visibility: Visibility of the generated `toolchain()` target.
    """
    binutils_toolchain(
        name = name + "_binutils",
        objcopy = bin(cpu, version, "objcopy"),
        objdump = bin(cpu, version, "objdump"),
        readelf = bin(cpu, version, "readelf"),
        tags = ["manual"],
    )

    constraints = [
        Label("@platforms//os:linux"),
        Label("@platforms//cpu:" + cpu),
    ]

    native.toolchain(
        name = name,
        exec_compatible_with = constraints,
        target_compatible_with = constraints,
        toolchain = ":" + name + "_binutils",
        toolchain_type = Label("//toolchains/binutils:toolchain_type"),
        visibility = visibility,
    )
