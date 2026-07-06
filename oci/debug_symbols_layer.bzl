"""Build an OCI layer of debug symbols gathered from an `oci_image`'s graph.

For SONiC: Given a runtime image of a component (e.g. docker-sysmgr), gather information about its dependencies,
figure out which debug symbols need to be produced, and place them into a tar, representing another layer.
"""

load("//binary:debug_symbols.bzl", "DebugSymbolsInfo")
load("//tar:debug_symbols_tar.bzl", "debug_symbols_tar")

_CollectedDebugSymbolsInfo = provider(
    doc = "Transitive union of DebugSymbolsInfo gathered across an image's dependency graph.",
    fields = {
        "symbols": "depset of debug TreeArtifacts collected from the whole graph.",
    },
)

# Attributes to gather tars from.
# Because sonic_deploy_tar already publishes transitive debug data, we don't need to traverse inside it,
# we can just traverse at the `rules_oci` level.
# Incidentally, this `tars` is doing double-duty. It traverses both `oci_image`'s `tars` attr, _and_ `flatten`'s `tars` attribute.
_CONTENT_ATTRS = ["base", "tars"]

def _collect_debug_symbols_impl(target, ctx):
    direct = target[DebugSymbolsInfo].symbols if DebugSymbolsInfo in target else depset()

    transitive = [direct]
    for attr_name in _CONTENT_ATTRS:
        value = getattr(ctx.rule.attr, attr_name, None)
        deps = value if type(value) == "list" else ([value] if value else [])
        for dep in deps:
            if _CollectedDebugSymbolsInfo in dep:
                transitive.append(dep[_CollectedDebugSymbolsInfo].symbols)

    return [_CollectedDebugSymbolsInfo(symbols = depset(transitive = transitive))]

_collect_debug_symbols = aspect(
    implementation = _collect_debug_symbols_impl,
    attr_aspects = _CONTENT_ATTRS,
    provides = [_CollectedDebugSymbolsInfo],
    doc = "Collects DebugSymbolsInfo across an image's dependency graph into _CollectedDebugSymbolsInfo.",
)

def _collected_debug_symbols_impl(ctx):
    # Surface the symbols the aspect gathered from the image graph as plain outputs
    # so copy_to_directory/tar can lay them out.
    return [DefaultInfo(files = ctx.attr.image[_CollectedDebugSymbolsInfo].symbols)]

_collected_debug_symbols = rule(
    implementation = _collected_debug_symbols_impl,
    doc = "Runs collect_debug_symbols over `image` and outputs the gathered .debug trees.",
    attrs = {
        "image": attr.label(
            mandatory = True,
            aspects = [_collect_debug_symbols],
            doc = "The runtime image to gather debug symbols from.",
        ),
    },
)

def _debug_symbols_layer_impl(name, visibility, image):
    collected = name + "_collected"
    _collected_debug_symbols(
        name = collected,
        image = image,
    )

    debug_symbols_tar(
        name = name,
        srcs = [":" + collected],
        visibility = visibility,
    )

debug_symbols_layer = macro(
    implementation = _debug_symbols_layer_impl,
    doc = "An OCI layer containing all the debug symbols relevant to `image`",
    attrs = {
        "image": attr.label(
            mandatory = True,
            doc = "The runtime image target",
        ),
    },
)
