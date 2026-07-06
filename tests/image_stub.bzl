"""A minimal mock for `oci_image`, used to test debug-symbol collection.

It has `base` and `tars`, same as `oci_image`, but doesn't produce anything itself.
Therefore, the only way for a test to pass is if the aspect gathers dependency information correctly.

If we were to use `oci_image` directly, we would need to provide actual base images,
as well as internet access, to run the tests.
"""

def _image_stub_impl(_ctx):
    return [DefaultInfo()]

image_stub = rule(
    implementation = _image_stub_impl,
    doc = "Mock exposing base/tars edges for the collect_debug_symbols aspect.",
    attrs = {
        "base": attr.label(
            doc = "A single base layer, mirroring oci_image's base attribute.",
        ),
        "tars": attr.label_list(
            doc = "Layered tars, mirroring oci_image's tars attribute.",
        ),
    },
)
