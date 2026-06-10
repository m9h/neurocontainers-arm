# mamba-ssm / causal-conv1d on aarch64 / GB10

Support for the **Mamba** state-space stack (`mamba-ssm` + `causal-conv1d`) on NVIDIA
Grace–Blackwell GB10 (DGX Spark, `sm_121`, aarch64). Needed by fMRI foundation models such
as MedARC's **NeuroSTORM** (Swin4D blocks embed `Mamba` layers).

## Generic conda use → conda-forge already works on GB10

For normal conda workflows you don't need to build anything — conda-forge ships the whole stack
for linux-aarch64 (CUDA 12.9), and it runs on GB10 (verified on DGX Spark, 2026-06):

```bash
mamba create -n mamba-gb10 -c conda-forge "cuda-version=12.9" \
    pytorch-gpu causal-conv1d mamba-ssm
python -c "import torch; from mamba_ssm import Mamba; \
  print(Mamba(d_model=64).cuda()(torch.randn(2,16,64,device='cuda')).shape)"
# torch 2.10 / cuda129 / mamba-ssm 2.3.1 / causal-conv1d 1.6.2.post1 — Mamba forward OK on GB10
```

PyTorch prints a benign `cuda capability 12.1 … max supported (12.0)` warning — GB10's `sm_121`
runs the conda-forge `sm_120` build via Blackwell forward-compat; kernels execute fine.

## NGC PyTorch container (torch 2.12 / CUDA 13) → use the prebuilt wheel here

These neurocontainers build `FROM nvcr.io/nvidia/pytorch:{24.12,26.03,26.04}-py3`. conda-forge's
`causal-conv1d` is built against conda's **PyTorch 2.10** and is ABI-specific — it will **not**
load against the NGC PyTorch (`2.12.0a0`, CUDA 13.2):

```
ImportError: selective_scan_cuda…so: undefined symbol: _ZNK3c104cuda10CUDAStream5queryEv
```

For the NGC stack, install the prebuilt wheel from this repo's
[releases](https://github.com/m9h/neurocontainers-arm/releases) (tag `causal-conv1d-1.6.2-cuda13-arm`):

```bash
pip install --no-build-isolation causal_conv1d-1.6.2.post1-cp312-cp312-linux_aarch64.whl
pip install --no-build-isolation mamba-ssm   # 2.3.x is JIT (tilelang/cutlass), arch-agnostic
```

| | |
|---|---|
| Wheel | `causal_conv1d-1.6.2.post1-cp312-cp312-linux_aarch64.whl` |
| Built against | NGC `nvcr.io/nvidia/pytorch:26.04-py3` — PyTorch `2.12.0a0`, CUDA 13.2 |
| Arch | `TORCH_CUDA_ARCH_LIST=12.1` → native **sm_121** (GB10) · Python 3.12 |

Rebuild for another torch/CUDA/arch (one command, run inside the target container with a GPU):

```bash
./build_causal_conv1d.sh ./dist      # edit TORCH_CUDA_ARCH_LIST for non-GB10 arches
```

## Which to use

| Environment | Use |
|---|---|
| Generic conda on GB10 / aarch64 | **conda-forge** (`cuda-version=12.9`) |
| NGC PyTorch container (torch 2.12 / CUDA 13) | the wheel / `build_causal_conv1d.sh` here |
| Non-Blackwell aarch64, other CUDA | `build_causal_conv1d.sh` with the right `TORCH_CUDA_ARCH_LIST` |

The wheel is a build of [Dao-AILab/causal-conv1d](https://github.com/Dao-AILab/causal-conv1d)
(BSD-3-Clause); credit to its authors. Redistributed here only for the NGC-container platform
upstream doesn't publish wheels for.
