"""Rule to wrap tar(), which ensures binaries are stripped, and creates tars with debug symbols"""

load("@tar.bzl//tar:tar.bzl", "tar", "tar_rule")
load("@bazel_lib//lib:utils.bzl", "propagate_common_rule_attributes")
load("//binary:strip_binary.bzl", "strip_binary")

def _sonic_deploy_tar_impl(name, binaries = {}, srcs = [], mtree = [], **kwargs):
  # We strip each binary and generate its mtree line pointing at the stripped ELF
  stripped_targets = []
  binary_mtree = []
  for mtree_prefix, binary in binaries.items():
    stripped_name = "{}_{}_stripped".format(name, binary.name)
    strip_binary(
      name = stripped_name,
      src = binary,
      **propagate_common_rule_attributes(kwargs)
    )

    # Pick apart the stripped binary and debug symbols
    stripped_file = stripped_name + "_file"
    native.filegroup(
      name = stripped_file,
      srcs = [":" + stripped_name],
      output_group = "stripped",
      visibility = kwargs["visibility"],
    )
    stripped_targets.append(":" + stripped_file)
    binary_mtree.append("{} content=$(location :{})".format(mtree_prefix, stripped_file))

  tar(
    name = name,
    srcs = srcs + stripped_targets,
    mtree = mtree + binary_mtree,
    **kwargs,
  )


sonic_deploy_tar = macro(
  implementation = _sonic_deploy_tar_impl,
  inherit_attrs = tar_rule,
  attrs = {
    "srcs": attr.label_list(
      default = [],
      allow_files = True,
      # We're referencing the srcs later in the mtree,
      # we can't make them configurable anyway.
      configurable = False,
    ),
    "mtree": attr.string_list(
      default = [],
      configurable = False,
    ),
    "binaries": attr.string_keyed_label_dict(
      doc = """Maps an mtree prefix (e.g. \"./usr/bin/foo uid=0 gid=0 mode=0755 type=file\") to a binary target.
The binary will then be replaced with its stripped version behind the scenes.
""",
      default = {},
      configurable = False,
    ),
    # We do not allow mutate for now, as we rely on messing with the mtree.
    "mutate": None,
  }
)

