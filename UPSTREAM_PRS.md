# Proposed upstream PRs — talking points for M. Reuter / Deep-MI

For Morgan's chat with M. Reuter. These are contributions we can upstream
from `m9h/neurocontainers-arm` to `Deep-MI/FastSurfer` and adjacent repos,
framed so Deep-MI can say yes or no cleanly per item.

## 1. Issue #716 — arm64 Dockerfile for FastSurfer seg

Minimum-surface PR. Fulfils what @dkuegler + @m-reuter explicitly asked
for in 2026-07 ("we'd love a PR to build a docker container for arm").

**Branch**: `feat/docker-arm-grace` against `dev`.

**Changes**:

- `tools/Docker/Dockerfile.grace` (new) — 30 lines, `FROM nvcr.io/nvidia/pytorch:24.12-py3`,
  filters torch/nvidia/triton from `requirements.txt`, `sed python3.10 → python3`.
  Single-arch arm64; seg-only operation documented in header (recon_surf
  needs a separate paired FreeSurfer 7.4.1 binary set which isn't yet
  in Deep-MI's distribution channel on arm64).
- `tools/Docker/build.py` — add `--device arm64` option that selects
  `Dockerfile.grace`. Keeps the existing `cu128` / `cpu` / `rocm`
  devices untouched.
- `.github/workflows/build-docker.yml` — optional: add arm64 matrix row
  on `[self-hosted, linux, arm64]`. Can be skipped if Deep-MI doesn't
  run arm64 runners; we publish locally on `ghcr.io/m9h/fastsurfer` in
  the meantime.
- `doc/overview/docker.rst` — 2-paragraph note on arm64 build +
  seg-only limitation.

**Source artefact**: user's verified-working Dockerfile at
<https://github.com/Deep-MI/FastSurfer/issues/716#issuecomment-...> (the
`Dockerfile.grace` attachment from 2026-01-03). Already validated on
DGX Spark GB10 Blackwell, 248 s per seg_only wave.

**Non-goals**: don't touch the amd64 Dockerfile, don't change the
run_fastsurfer.sh interface.

## 2. Full arm64 FastSurfer (seg + recon_surf) — `fastsurfer-full`

Relies on the separately-built `freesurfer-7.4.1_7.4.1-1_arm64.deb` from
Morgan's NeuroDebian work. Because that package is not yet in
NeuroDebian main, this is staged as:

**Option A** (upstream into `Deep-MI/FastSurfer`): add as an opt-in
variant once neurodebian ships 7.4.1 officially. Too early today — the
deb only lives in `m9h`'s local build tree.

**Option B** (self-host in `m9h/neurocontainers-arm`): already done.
`ghcr.io/m9h/fastsurfer-full:7.4.1-<fs-commit>.1` is the public home.
No Deep-MI PR until the 7.4.1 .deb is in Debian/NeuroDebian.

Ask M. Reuter: would Deep-MI be interested in a link from their
`doc/overview/INSTALL.md` pointing users at the arm64 companion
container while the upstream plan for arm64 recon_surf takes shape?
Low-commitment, high-value for users on Apple Silicon / AWS Graviton /
NVIDIA Grace.

## 3. `FS_VERSION_SUPPORT` relaxation (tiny)

`run_fastsurfer.sh` currently errors out on any FreeSurfer != 7.4.1
unless `--ignore_fs_version` is passed. Our arm64 containers ship 7.4.1
for compatibility, but some users may want to pair FastSurfer with a
newer FS they've got from their own distro.

Proposal: change the hard-error to a warning when the version is
newer than 7.4.1, not older. Keeps the safety net for old FS installs
but doesn't punish users on newer stable releases. ~5 lines.

**Only raise if** M. Reuter thinks it's in scope; otherwise drop.

## 4. Separately to the NeuroDebian / Debian-science list

Not a Deep-MI PR, but worth mentioning:

- `freesurfer-7.4.1_7.4.1-1_arm64.deb` + `freesurfer_8.2.0-3_arm64.deb`
  + `freesurfer-python_8.2.0-1_all.deb` — NeuroDebian ITP candidates.
- `python3-surfa`, `python3-voxelmorph`, `python3-neurite` — ITPs that
  would let `freesurfer-python` drop its venv-bootstrap fallback.

M. Reuter's endorsement of the source/patch set would unblock
NeuroDebian sponsorship.

## Non-asks (deliberate)

- We are NOT asking Deep-MI to ship/host our `-grace.*` tags
  permanently on ghcr.io.
- We are NOT asking them to maintain the .deb build — the neurodebian
  agent handles that.
- We are NOT asking for commitment to publish arm64 multi-arch
  manifests for every FastSurfer release.

Just: `Dockerfile.grace` into `tools/Docker/`, honourable mention in
install docs, optional CI matrix. Minimal maintenance.
