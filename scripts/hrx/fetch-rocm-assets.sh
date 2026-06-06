#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

. "${SCRIPT_DIR}/env.sh"

python3 "${HRX_SRC_DIR}/build_tools/ci_core_linux.py" fetch-rocm

export ROCM_PATH="${HRX_ROCM_ROOT}"
export CMAKE_PREFIX_PATH="${HRX_ROCM_ROOT}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export PATH="${HRX_ROCM_ROOT}/lib/llvm/bin:${HRX_ROCM_ROOT}/bin:${PATH}"
export LD_LIBRARY_PATH="${HRX_ROCM_ROOT}/lib:${HRX_ROCM_ROOT}/lib/rocm_sysdeps/lib:${LD_LIBRARY_PATH:-}"

"${HRX_ROCM_ROOT}/lib/llvm/bin/amdclang" --version
"${HRX_ROCM_ROOT}/lib/llvm/bin/amdclang++" --version
