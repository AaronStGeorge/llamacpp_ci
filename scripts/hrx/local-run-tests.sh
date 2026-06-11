#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git -C "${SCRIPT_DIR}" rev-parse --show-toplevel)"

. "${SCRIPT_DIR}/local-env.sh"
. "${SCRIPT_DIR}/runtime-env.sh"

TEST_BACKEND_OPS="${LLAMA_BUILD_DIR}/bin/test-backend-ops"
if [[ ! -x "${TEST_BACKEND_OPS}" ]]; then
    echo "Error: test-backend-ops not found at ${TEST_BACKEND_OPS}" >&2
    echo "Run local-build-llama.sh first." >&2
    exit 1
fi

OPERATION="${1:-MUL_MAT}"
if [[ $# -gt 0 ]]; then
    OPERATION="$1"
    shift
fi

# Backend to test (test-backend-ops -b). Override for CPU-only hosts: TEST_BACKEND=CPU.
TEST_BACKEND="${TEST_BACKEND:-HRX0}"

"${TEST_BACKEND_OPS}" test -o "${OPERATION}" -b "${TEST_BACKEND}" "$@"
