# neurocontainers-arm

Arm64 (aarch64) container images for common neuroimaging pipelines, built
for the NVIDIA Grace–Blackwell generation (DGX Spark and successors).
Maintained because upstream images are typically amd64-only; these fill
the gap.

Published on [GitHub Container Registry](https://github.com/orgs/m9h/packages):

| Image | Tag scheme | License of the wrapped tool |
|---|---|---|
| [`ghcr.io/m9h/t1prep-arm`](https://github.com/m9h/neurocontainers-arm/pkgs/container/t1prep-arm) | `<t1prep-version>-arm.<patch-rev>` (e.g. `v0.3.3-arm.1`) | Apache-2.0 |
| [`ghcr.io/m9h/fastsurfer-arm`](https://github.com/m9h/neurocontainers-arm/pkgs/container/fastsurfer-arm) | `<fastsurfer-commit>-arm.<patch-rev>` | Apache-2.0 wrapper, FreeSurfer-NC for binaries the user pulls at runtime |
| [`ghcr.io/m9h/medarc-arm`](https://github.com/m9h/neurocontainers-arm/pkgs/container/medarc-arm) | `<medarc-commit>-arm.<patch-rev>` | Apache-2.0 pipeline, FreeSurfer-NC for included FS binaries |

All images FROM `nvcr.io/nvidia/pytorch:{24.12,26.03}-py3` so the
PyTorch / CUDA / cuDNN stack is NVIDIA-optimised for Grace-Blackwell
(`sm_120`).

## Licenses

- These recipes are MIT-licensed (see `LICENSE`).
- **Upstream tools have their own licenses:**
  - T1Prep (ChristianGaser/T1Prep) — Apache 2.0.
  - FastSurfer (Deep-MI/FastSurfer) — Apache 2.0.
  - **FreeSurfer** — MGH non-commercial research license. Binaries
    shipped in `fastsurfer-arm` and `medarc-arm` require a user-provided
    `license.txt` at runtime; we do NOT bake it in. Get yours at
    <https://surfer.nmr.mgh.harvard.edu/registration.html>.
- Each image's `LABEL org.opencontainers.image.licenses=` field records
  the effective license for that image.

## Usage (quick)

```bash
# T1Prep — runs on any arm64 GPU with CUDA 13+ drivers.
docker run --gpus all --rm -v /path/to/anat:/input:ro -v /path/to/out:/output \
    ghcr.io/m9h/t1prep-arm:v0.3.3-arm.1 \
    --out-dir /output --gz /input/sub-XXX_T1w.nii.gz

# FastSurfer seg_only — requires a FreeSurfer license file.
docker run --gpus all --rm \
    -v ~/license.txt:/opt/FastSurfer/license.txt:ro \
    -v ~/fs_checkpoints:/opt/FastSurfer/checkpoints:ro \
    -v /path/to/anat:/data:ro -v /path/to/out:/output \
    ghcr.io/m9h/fastsurfer-arm:latest \
    ./run_fastsurfer.sh --t1 /data/T1w.nii.gz --sid sub-XXX --sd /output \
        --seg_only --parallel --fs_license /opt/FastSurfer/license.txt
```

## Why arm64

- **NVIDIA Grace (DGX Spark)** is arm64 + Blackwell; upstream
  neuroimaging Dockerfiles are almost entirely amd64 and fall back to
  QEMU emulation on Grace, which is unusably slow for TF/PyTorch
  inference.
- **Wider Apple Silicon / AWS Graviton compatibility** is a free
  side-effect.
- **MGH's own `freesurfer/freesurfer:*` images** are amd64 only as of
  2026-04; this repo ships locally-built arm64 .debs for FreeSurfer
  8.2.0 inside `fastsurfer-arm` and `medarc-arm`.

## Build locally

```bash
cd Dockerfiles/t1prep-arm
docker build --platform=linux/arm64 -t t1prep-arm:local .
```

Each Dockerfile is self-contained except `fastsurfer-arm` (needs the
FastSurfer source tree as build context) and `medarc-arm` (needs local
arm64 FreeSurfer .debs in the build context — see that directory's
README).

## Known divergences from upstream

- **t1prep-arm** carries three Blackwell-specific patches not yet
  upstreamed (see `Dockerfiles/t1prep-arm/PATCHES.md`): deterministic
  flag `warn_only=True`, write perms on weight-cache, case-sensitive
  atlas filenames.
- **fastsurfer-arm** is seg_only; upstream `recon-surf` calls FreeSurfer
  binaries that aren't ported arm64 until this repo's MGH-sourced
  .debs ship.

## Auto-build

`.github/workflows/build.yml` rebuilds all three on tag push and
publishes to `ghcr.io/m9h/<image>:<tag>`. Self-hosted arm64 runner
required (GitHub-hosted arm64 runners are GA but still limited; local
runner recommended for the fat NGC base pulls).

## Upstream contribution status

- T1Prep patches: PR pending (ChristianGaser/T1Prep).
- FastSurfer arm Dockerfile: PR pending (Deep-MI/FastSurfer#716
  explicitly solicited it).
- NeuroContainers recipes for Neurodesk: pending.
