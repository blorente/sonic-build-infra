"""Analysis test asserting a strip_binary target advertises its debug symbols.

Unlike assert_stripped (which runs the stripped ELF through objdump/readelf),
this only inspects providers, it doesn't even need to build the binaries.
"""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(":debug_symbols.bzl", "DebugSymbolsInfo")

def _provides_debug_symbols_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.true(
        env,
        DebugSymbolsInfo in target,
        "strip_binary target must provide DebugSymbolsInfo",
    )

    symbols = target[DebugSymbolsInfo].symbols.to_list()
    asserts.equals(
        env,
        1,
        len(symbols),
        "expected exactly one debug tree artifact",
    )
    asserts.true(
        env,
        symbols[0].basename.endswith(".debug"),
        "symbol artifact must be the .debug tree, got: " + symbols[0].basename,
    )

    return analysistest.end(env)

provides_debug_symbols_test = analysistest.make(_provides_debug_symbols_test_impl)
