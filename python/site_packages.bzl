load("@rules_python//python:defs.bzl", "PyInfo")
load("@tar.bzl", "mutate", "tar")

def _export_pyinfo(ctx):
    files = []
    filter = ctx.attr.exclude_filter
    for dep in ctx.attr.srcs:
        files_to_export = []
        # TODO(bazel-ready): This is terribly inefficient, ideally we'd implement this functionality in tar.bzl
        for file in dep[PyInfo].transitive_sources.to_list():
            if filter == "" or filter not in file.path:
                files_to_export.append(file)

        files.append(depset(files_to_export))
    return DefaultInfo(files = depset([], transitive = files))

export_py_info = rule(
    implementation = _export_pyinfo,
    doc = "Export `PyInfo.transitive_sources` as DefaultInfo.",
    attrs = {
        "srcs": attr.label_list(
            providers = [PyInfo],
        ),
        "exclude_filter": attr.string(
            doc = "If set, exclude any file containing the filter from being exported. Does not support globbing.",
            default = "",
        ),
    }
)

def site_packages(name, srcs, exclude_filter = "", **kwargs):
    """
    Conveninece macro to create a tar with a bunch of python dependencies.
    srcs must export the required files with `PyInfo`.
    """
    export_py_info(
        name = name + "_info",
        srcs = srcs,
        exclude_filter = exclude_filter,
    )
    tar(
        name = name,
        srcs = [":" + name + "_info"],
        **kwargs
    )
