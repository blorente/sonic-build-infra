# Source pull request CI

`Bazel (AMD64)` and `Bazel (ARM64)` run on native GitHub-hosted Ubuntu
runners in the same pinned Debian Trixie image. PR events cover all branches
and paths; push events also validate `master`. Checkout uses the proposed merge
revision, so the checks exercise the current PR with its target branch.

Run `bash ci/bazel-ci.sh` on a native AMD64 or ARM64 Debian Trixie host with
Bazel 8.5.1, a C/C++ compiler, binutils, GDB, Git, Python, tar and xz installed.
Local builds default to `sonic-bazel-registry/main` and the Bazel Central
Registry. The locked native APT interfaces request `rules_distroless`
`0.9.4.sonic.17` from [registry #207](https://github.com/securely1g/sonic-bazel-registry/pull/207),
preserving the individual header and library exports. This Draft also depends on
[registry #204](https://github.com/securely1g/sonic-bazel-registry/pull/204) (gawk),
[#205](https://github.com/securely1g/sonic-bazel-registry/pull/205) (rules_python),
[#206](https://github.com/securely1g/sonic-bazel-registry/pull/206) (tar.bzl), and
[#159](https://github.com/securely1g/sonic-bazel-registry/pull/159) (Gazelle).

For this Draft's `pr/locked-migration-interfaces-20261103` branch only, both
native workflows replace the maintained SONiC endpoint with the complete reviewed
candidate catalog at
`https://raw.githubusercontent.com/securely1g/sonic-bazel-registry/ec6757295100aa30f7f911dd180af7d84c66761b`.
Other PRs, pushes and manual runs retain `main`, and `.bazelrc` remains unchanged.
The candidate contains the pending prerequisites; it is neither a fallback to a
second version of the same registry nor evidence that those PRs have merged.
Remove this temporary branch override after the dependencies are published.
The PR remains Draft while those prerequisites are outstanding.

Reproduce the Draft source checks on a native Trixie host with:

```sh
SONIC_BAZEL_REGISTRY=https://raw.githubusercontent.com/securely1g/sonic-bazel-registry/ec6757295100aa30f7f911dd180af7d84c66761b \
  bash ci/bazel-ci.sh
```

The script ignores user/workspace rc files and selects exactly one SONiC endpoint
plus BCR. It checks the committed APT lock before building, generates
`MODULE.bazel.lock`, and records the resolved module graph and endpoint with the
CI evidence; the generated module lock remains ignored.

Distroless patches, upstream regressions and package-import consumer tests live
with the [registry module](https://github.com/securely1g/sonic-bazel-registry/tree/main/modules/rules_distroless).
This repository tests its own SONiC rules, toolchains and APT adapters against
the selected dependency recipe; it does not maintain a second Distroless
patch archive or test suite.

The separate shared-Rust workspace uses its unchanged BCR dependencies. The
source script selects matching execution/target platforms. Module versions, source
checksums and package snapshots remain explicit inputs. The repository deliberately
excludes its large generated module lock; CI retains the resolved lock as evidence.

The explicit source tests cover C/C++ linking, shared-library/PIC behavior,
stripping and deployment debug-provider/content behavior. The protoc smoke test
generates C++, Python and Python type stubs with imported schemas and proto3
optional fields using its declared compiler runtime. The shared API branch
also runs the nine external-consumer analysis/sysroot tests and rejects the
unsafe archive fixture. Wheel installation tests run when the wheel-layer rule
is present; archive ownership and debug-header ownership tests run when the
ownership rule is present. These rule families are selected independently, so
either can be developed and validated on its own. The native matrix also selects
the three existing Bookworm contracts:
`//cc/tests/header_includes:headers_link_test` builds and inspects an executable
and shared library using `@bookworm_build_tools//libperl-dev:libperl_cc`;
`//toolchains/bookworm/tests:abi_test` checks the target ELF ABI; and
`:native_test` executes it with the declared Bookworm runtime. They keep Trixie
execution tools and select the matching Bookworm target architecture, retaining
a separate action audit, test events and logs. These checks do not claim
ARMHF execution, an installed SONiC image, or full component downstream coverage.

The native source matrix explicitly runs runtime-context and native-runtime
contracts, including per-object ORIGIN, RPATH inheritance and RUNPATH isolation,
checker argument forwarding, installation RPATH preservation and GCC prefix maps.
The declared-tool matrix also runs the Trixie test runtime, Bookworm Perl and
Bookworm Valgrind contracts on both native architectures, including changes
limited to `apt/**` or `toolchains/bookworm/**`. Source and declared-tool tests
run with cached test results disabled. The source matrix explicitly runs
`//apt:bookworm_lock_test` against the committed lock to check the three Bookworm
dependency sets on both architectures, including package closures and native
header/library exports.

Archive timestamp checks cover the shared default and caller overrides, explicit
zero times, and both direct tar and stripped-binary deployment paths. The tar.bzl
patch owns generic manifest and changed-input-mtime regressions. The source
workflow retains a plain tar and a runtime/debug pair using omitted timestamps
as well as the existing deployment samples. It also records the effective
registry URL and generated module lock for dependency inspection.

Both architectures prepare the declared kernel build runtime and check its
archive boundaries, compiler, Python packaging modules and Debian shared-library
dependency calculation. The runtime check relocates the declared tools and
uses their private loaders, interpreters and data without `chroot` or device
creation. It compiles and runs native C/C++ host programs, checks the ordinary
deployment interpreter, and, on ARM64, compiles an ARM32 compatibility
vDSO probe. These checks create no DEB packages or kernel image.

Each run retains test XML/logs, build events, native host metadata, revision,
resolved module locks, the APT lock and its source/request inputs, sample
executables, and their runtime/debug deployment tars. Successful runs include
checksums in `provenance.json`. Download the architecture-specific artifact from the Actions run page. Partial evidence is
retained when a validation step fails.

The installed deployment-tar check verifies the complete runtime file set,
payload ownership and modes, declared data bytes, native ELF architecture,
execution of the extracted program, matching build IDs, debuglink checksum,
and GDB source-line lookup through the extracted debug tree. Its report is
retained as `deploy-archives.json` alongside both archives.

CI selects runtime/debug tar outputs directly. The separate Debian-control
workflow is removed so source PRs do not create fixture DEBs. Legacy Debian
rules and fixtures remain available for explicitly authorized DEB validation;
they are outside the automatic source CI selections.

Both architecture checks must be required on the PR target branch. Repository
settings enforce this separately from the workflow; skipped or missing jobs
are not successful source coverage.
