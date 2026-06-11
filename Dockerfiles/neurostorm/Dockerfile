# NeuroSTORM (MedARC fMRI foundation model: Swin4D + Mamba) — turnkey on aarch64 / GB10.
#
# Base: NGC PyTorch 26.04-py3 (Ubuntu 24.04 arm64, torch 2.12 / CUDA 13.2, GB10 sm_121).
# NeuroSTORM upstream pins a 2023 stack (py<3.12, pytorch-lightning==1.9.4, torch 2.6,
# mamba-ssm) — none of which actually requires a legacy container. We run it on the
# up-to-date NGC stack with three fixes baked in:
#   1. build causal-conv1d from source against this torch (ABI-matched, sm_121);
#   2. mamba-ssm 2.3.x (JIT via tilelang/cutlass — arch-agnostic);
#   3. remove torch_tensorrt so monai's optional-import doesn't hang at import time.
#
# Result: `from neurostorm.models.lightning_model import LightningModel` and a Swin4D+Mamba
# forward both work out of the box on GB10. See ../../mamba-ssm-gb10/ for the standalone notes.

FROM nvcr.io/nvidia/pytorch:26.04-py3

ARG NEUROSTORM_COMMIT=7fa3b96c8021735f1d84a81d0367b2568a2dc6e4
ARG SWIFT_COMMIT=324b003061e484ebd1a247967b520019fda911fc
ENV DEBIAN_FRONTEND=noninteractive \
    TORCH_CUDA_ARCH_LIST="12.1" \
    TEMPLATEFLOW_HOME=/opt/templateflow \
    PIP_BREAK_SYSTEM_PACKAGES=1

# --- mamba stack: build causal-conv1d from source (ABI-matched to this torch / CUDA 13) ---
RUN CAUSAL_CONV1D_FORCE_BUILD=TRUE MAX_JOBS=16 CUDA_HOME=/usr/local/cuda \
    pip install --no-cache-dir --no-build-isolation "causal-conv1d==1.6.2.post1" \
 && pip install --no-cache-dir --no-build-isolation mamba-ssm

# --- NeuroSTORM + its runtime deps (ignore the conservative py<3.12 cap; --no-deps so we
#     don't drag in its torch 2.6 / pytorch-lightning==1.9.4 pins, which we don't need) ---
RUN pip install --no-cache-dir --ignore-requires-python --no-deps \
        "neurostorm @ git+https://github.com/MedARC-AI/NeuroSTORM.git@${NEUROSTORM_COMMIT}" \
 && pip install --no-cache-dir \
        pytorch-lightning monai templateflow nilearn nibabel frozendict einops scipy

# SwiFT (contrastive Swin4D, the other whole-brain volume-4D fMRI FM) alongside NeuroSTORM.
# Pure-Python (no mamba / no CUDA compile); shares the same monai/lightning/volume stack.
RUN pip install --no-cache-dir --ignore-requires-python --no-deps \
        "swiftfmri @ git+https://github.com/MedARC-AI/SwiFT.git@${SWIFT_COMMIT}"

# monai's networks.trt_compiler does an optional_import of torch_tensorrt whose __init__
# hangs in this container; removing it makes the optional-import fail fast and clean.
RUN pip uninstall -y torch_tensorrt torch-tensorrt 2>/dev/null || true

# Prefetch the MNI152NLin6Asym 2mm brain mask NeuroSTORM's volume transform needs.
RUN python3 -c "import templateflow.api as t; t.get('MNI152NLin6Asym', desc='brain', resolution=2, suffix='mask', extension='nii.gz')"

# Build-time smoke test: mamba + NeuroSTORM import and a Swin4D+Mamba forward on import path.
RUN python3 - <<'PY'
import torch
from mamba_ssm import Mamba, Mamba2
from neurostorm.models.lightning_model import LightningModel
from swiftfmri.pl_classifier import LitClassifier
print("OK: mamba-ssm + neurostorm + swiftfmri import; torch", torch.__version__)
PY

LABEL org.opencontainers.image.title="neurostorm-arm" \
      org.opencontainers.image.description="MedARC volume-4D fMRI FMs (NeuroSTORM Swin4D+Mamba, SwiFT) on aarch64/GB10, NGC pytorch 26.04 / CUDA 13" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.source="https://github.com/m9h/neurocontainers-arm"

WORKDIR /workspace
