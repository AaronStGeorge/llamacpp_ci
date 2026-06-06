#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
    echo "Usage: $0 <repository> <fetch-ref> <checkout-ref> <src-dir>" >&2
    exit 2
fi

repository="$1"
fetch_ref="$2"
checkout_ref="$3"
src_dir="$4"

if [[ -d "${src_dir}/.git" ]]; then
    git -C "${src_dir}" remote set-url origin "${repository}"
else
    mkdir -p "$(dirname "${src_dir}")"
    git clone --filter=blob:none --no-checkout "${repository}" "${src_dir}"
fi

git -C "${src_dir}" fetch origin "${fetch_ref}" --depth=1

if ! git -C "${src_dir}" checkout --detach "${checkout_ref}" 2>/dev/null; then
    git -C "${src_dir}" fetch origin "${checkout_ref}" --depth=1
    git -C "${src_dir}" checkout --detach FETCH_HEAD
fi

actual_ref="$(git -C "${src_dir}" rev-parse HEAD)"
if [[ "${checkout_ref}" =~ ^[0-9a-f]{40}$ && "${actual_ref}" != "${checkout_ref}" ]]; then
    echo "Expected ${src_dir} at ${checkout_ref}, got ${actual_ref}" >&2
    exit 1
fi

echo "${actual_ref}"
