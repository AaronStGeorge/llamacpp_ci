#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

. "${SCRIPT_DIR}/env.sh"

"${HRX_INSTALL_PREFIX}/bin/hrx-info" --device=cpu:0
