#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"

export HRX_WORK_DIR="${HRX_WORK_DIR:-${REPO_ROOT}}"
export HRX_SRC_DIR="${HRX_SRC_DIR:-${HRX_WORK_DIR}/assets/hrx-src}"
export HRX_ROCM_ROOT="${HRX_ROCM_ROOT:-${HRX_WORK_DIR}/assets/hrx-rocm-root}"
export HRX_DOWNLOAD_CACHE_DIR="${HRX_DOWNLOAD_CACHE_DIR:-${HRX_WORK_DIR}/assets/hrx-rocm-downloads}"
export HRX_BUILD_DIR="${HRX_BUILD_DIR:-${REPO_ROOT}/build-hrx}"
export HRX_INSTALL_PREFIX="${HRX_INSTALL_PREFIX:-${REPO_ROOT}/build-hrx-install}"

"${SCRIPT_DIR}/run-build.sh" "$@"
