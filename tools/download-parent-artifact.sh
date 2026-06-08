#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <artifact-name> <output-dir>" >&2
    exit 2
fi

artifact_name="$1"
output_dir="$2"

: "${GITHUB_WORKFLOW:?GITHUB_WORKFLOW is required}"
: "${GITHUB_RUN_ID:?GITHUB_RUN_ID is required}"

mkdir -p "${output_dir}"

parent_sha="${PARENT_SHA:-}"
if [[ -z "${parent_sha}" ]]; then
    if ! parent_sha="$(git rev-parse HEAD^ 2>/dev/null)"; then
        echo "Could not resolve parent commit. Set PARENT_SHA or fetch enough git history."
        exit 0
    fi
fi

if [[ "${parent_sha}" == "0000000000000000000000000000000000000000" ]]; then
    echo "Parent commit is the all-zero SHA; skipping artifact download."
    exit 0
fi

run_id="$(
    gh run list \
        --workflow "${GITHUB_WORKFLOW}" \
        --commit "${parent_sha}" \
        --status success \
        --limit 1 \
        --json databaseId \
        --jq '.[0].databaseId'
)"

if [[ -z "${run_id}" || "${run_id}" == "null" ]]; then
    echo "No successful run found for parent commit ${parent_sha}."
    exit 0
fi

if [[ "${run_id}" == "${GITHUB_RUN_ID}" ]]; then
    echo "Resolved current run ${run_id}; skipping self-download."
    exit 0
fi

if ! gh run download "${run_id}" \
    --name "${artifact_name}" \
    --dir "${output_dir}"; then
    echo "Parent run ${run_id} has no ${artifact_name} artifact."
    exit 0
fi

echo "Downloaded ${artifact_name} from parent commit ${parent_sha}, run ${run_id}."
