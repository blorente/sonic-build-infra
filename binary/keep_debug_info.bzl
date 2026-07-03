"""Build a binary, but make sure we're producing debug info.

This sets `--strip` to `never` and manually adding the compiler and linker flags needed to produce the info.
"""

def _keep_debug_info_transition_impl(settings, attr):
    return {
        "//command_line_option:strip": "never",
        "//command_line_option:copt": settings["//command_line_option:copt"] + ["-g"],
        "//command_line_option:linkopt": settings["//command_line_option:linkopt"] + ["-Wl,--build-id"],
    }

_keep_debug_info_transition = transition(
    implementation = _keep_debug_info_transition_impl,
    inputs = [
        "//command_line_option:copt",
        "//command_line_option:linkopt",
    ],
    outputs = [
        "//command_line_option:strip",
        "//command_line_option:copt",
        "//command_line_option:linkopt",
    ],
)

def _keep_debug_info_impl(ctx):
    # Just forward the src, the transition did the real work.
    return [DefaultInfo(files = depset(ctx.files.src))]

keep_debug_info = rule(
    implementation = _keep_debug_info_impl,
    doc = "Make sre `src` is built with debug infor retained, for feeding to strip_binary in tests.",
    attrs = {
        "src": attr.label(
            mandatory = True,
            allow_single_file = True,
            cfg = _keep_debug_info_transition,
            doc = "The binary to rebuild with debug info retained.",
        ),
        "_allowlist_function_transition": attr.label(
            default = "@bazel_tools//tools/allowlists/function_transition_allowlist",
        ),
    },
)
