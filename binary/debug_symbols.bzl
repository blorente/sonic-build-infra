"""Provider carrying extracted debug symbols so they can be gathered automatically with an aspect when we're assembling debug containers.
"""

DebugSymbolsInfo = provider(
    doc = "Transitive set of extracted debug-symbol tree artifacts (.build-id/NN/REST.debug).",
    fields = {
        "symbols": "depset[File] of debug TreeArtifacts, each laid out as .build-id/NN/REST.debug.",
    },
)
