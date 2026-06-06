#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

. "${SCRIPT_DIR}/env.sh"
"${SCRIPT_DIR}/checkout-llama.sh"

GGML_HRX_AMDGPU_TARGETS="${GGML_HRX_AMDGPU_TARGETS:-gfx1100}"
GGML_HRX_BUILD_HIP_BENCHES="${GGML_HRX_BUILD_HIP_BENCHES:-OFF}"
LLAMA_BUILD_TARGET="${LLAMA_BUILD_TARGET:-}"

if [[ -z "${ROCM_PATH:-}" ]]; then
    ROCM_PATH="${HRX_ROCM_ROOT}"
    export ROCM_PATH
fi

CMAKE_PREFIX_PATH="${HRX_INSTALL_PREFIX}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export CMAKE_PREFIX_PATH

cmake_args=(
    -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}"
    -DGGML_HRX=ON
    -DGGML_NATIVE=OFF
    -DGGML_HRX_ROCM_PATH="${ROCM_PATH}"
    -DGGML_HRX_AMDGPU_TARGETS="${GGML_HRX_AMDGPU_TARGETS}"
    -DGGML_HRX_BUILD_HIP_BENCHES="${GGML_HRX_BUILD_HIP_BENCHES}"
    -DCMAKE_C_COMPILER="${ROCM_PATH}/lib/llvm/bin/amdclang"
    -DCMAKE_CXX_COMPILER="${ROCM_PATH}/lib/llvm/bin/amdclang++"
)

configure_args=(-S "${LLAMA_SRC_DIR}" -B "${LLAMA_BUILD_DIR}" -G "${CMAKE_GENERATOR}")
cmake "${configure_args[@]}" "${cmake_args[@]}" "$@"

build_args=(--build "${LLAMA_BUILD_DIR}" --config "${CMAKE_BUILD_TYPE}" -j "${LLAMA_BUILD_JOBS:-$(nproc)}")
if [[ -n "${LLAMA_BUILD_TARGET}" ]]; then
    build_args+=(--target "${LLAMA_BUILD_TARGET}")
fi

cmake "${build_args[@]}"
