#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

. "${SCRIPT_DIR}/env.sh"

"${SCRIPT_DIR}/checkout-repo.sh" "${LLAMA_REPOSITORY}" "${LLAMA_FETCH_REF}" "${LLAMA_CHECKOUT_REF}" "${LLAMA_SRC_DIR}"
