#!/usr/bin/env bash
# Build causal-conv1d for aarch64 / NVIDIA GB10 (DGX Spark), CUDA 13, inside the
# NGC PyTorch 26.04 container. Produces a cp312 aarch64 wheel.
set -euo pipefail
export TORCH_CUDA_ARCH_LIST="12.1"        # GB10 = sm_121; use "12.0+PTX" for forward-compat
export CAUSAL_CONV1D_FORCE_BUILD=TRUE
export MAX_JOBS="${MAX_JOBS:-16}"
export CUDA_HOME=/usr/local/cuda
OUT="${1:-./dist}"; mkdir -p "$OUT"
python - <<'PY'
import torch; print("torch", torch.__version__, "cuda", torch.version.cuda)
print("device cc", torch.cuda.get_device_capability(0) if torch.cuda.is_available() else "cpu")
PY
pip wheel --no-build-isolation --no-deps "causal-conv1d==1.6.2.post1" -w "$OUT"
echo "wheel(s) in $OUT:"; ls -la "$OUT"/*.whl
