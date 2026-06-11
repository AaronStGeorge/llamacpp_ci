#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

. "${SCRIPT_DIR}/env.sh"

python3 "${SCRIPT_DIR}/fetch-rocm-assets.py"

"${HRX_ROCM_ROOT}/lib/llvm/bin/amdclang" --version
"${HRX_ROCM_ROOT}/lib/llvm/bin/amdclang++" --version
