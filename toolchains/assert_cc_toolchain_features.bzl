"""Assert that the resolved cc toolchain enables a set of features.

Some of what a toolchain advertises (e.g. cc_tool_capability lists) is invisible in the BUILD graph.
So assert it directly, against the toolchain Bazel actually resolves.
"""

load("@rules_cc//cc:find_cc_toolchain.bzl", "find_cpp_toolchain", "use_cc_toolchain")
load("@rules_cc//cc/common:cc_common.bzl", "cc_common")

def _assert_cc_toolchain_features_test_impl(ctx):
    cc_toolchain = find_cpp_toolchain(ctx)
    feature_configuration = cc_common.configure_features(
        ctx = ctx,
        cc_toolchain = cc_toolchain,
        requested_features = ctx.features,
        unsupported_features = ctx.disabled_features,
    )

    missing = [
        feature
        for feature in ctx.attr.enabled
        if not cc_common.is_enabled(
            feature_configuration = feature_configuration,
            feature_name = feature,
        )
    ]

    # Report as a failing test rather than an analysis failure, so that we see the reports the same way as other tests.
    exe = ctx.actions.declare_file(ctx.label.name + ".sh")
    if missing:
        script = '#!/usr/bin/env bash\necho "ASSERT FAILED: cc toolchain does not enable: {}" >&2\nexit 1\n'.format(
            ", ".join(missing),
        )
    else:
        script = "#!/usr/bin/env bash\necho OK\n"
    ctx.actions.write(exe, script, is_executable = True)

    return [DefaultInfo(executable = exe)]

assert_cc_toolchain_features_test = rule(
    implementation = _assert_cc_toolchain_features_test_impl,
    doc = "Fails if the resolved cc toolchain does not enable every named feature.",
    test = True,
    attrs = {
        "enabled": attr.string_list(
            mandatory = True,
            doc = "Feature names that must be enabled, e.g. `supports_pic`.",
        ),
    },
    fragments = ["cpp"],
    toolchains = use_cc_toolchain(),
)
