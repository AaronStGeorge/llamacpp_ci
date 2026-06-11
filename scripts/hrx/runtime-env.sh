# Environment derived from the composed ROCm prefix + build outputs, for any
# script that builds or runs against them. Source after env.sh or local-env.sh.
#
# Idempotent enough: repeat sourcing only duplicates entries in
# $CMAKE_PREFIX_PATH $PATH and $LD_LIBRARY_PATH.

export ROCM_PATH="${ROCM_PATH:-${HRX_ROCM_ROOT}}"
export CMAKE_PREFIX_PATH="${HRX_ROCM_ROOT}${CMAKE_PREFIX_PATH:+:${CMAKE_PREFIX_PATH}}"
export PATH="${HRX_ROCM_ROOT}/lib/llvm/bin:${HRX_ROCM_ROOT}/bin:${PATH}"

# Composed-prefix ROCm libs, the local HRX install (libhrx), and sibling llama
# build-tree libs (libmtmd) are not on the default loader path.
export LD_LIBRARY_PATH="${HRX_ROCM_ROOT}/lib:${HRX_ROCM_ROOT}/lib/rocm_sysdeps/lib:${HRX_INSTALL_PREFIX}/lib:${LLAMA_BUILD_DIR}/bin:${LD_LIBRARY_PATH:-}"

# gfx12 GPUs do not expose a fine-grained VRAM pool by default, failing HRX's
# allocator ("requires fine-grained device-local memory"). Only force it there;
# earlier archs (e.g. gfx11) don't need it. Pre-set HSA_FORCE_FINE_GRAIN_PCIE to override.
if [[ -z "${HSA_FORCE_FINE_GRAIN_PCIE:-}" ]] &&
        "${HRX_ROCM_ROOT}/bin/rocm_agent_enumerator" 2>/dev/null | grep -q '^gfx12'; then
    export HSA_FORCE_FINE_GRAIN_PCIE=1
fi
