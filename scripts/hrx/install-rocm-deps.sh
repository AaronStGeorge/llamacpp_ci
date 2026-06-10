#!/usr/bin/env bash
set -euo pipefail

APT_INSTALL=(sudo apt-get install -y --no-install-recommends)

# Reclaim disk space on GitHub-hosted runners only; these paths belong to the
# hosted image and must not be removed on self-hosted runners.
if [[ "${GITHUB_ACTIONS:-}" == "true" && "${RUNNER_ENVIRONMENT:-}" == "github-hosted" ]]; then
    df -h /
    sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/share/boost /opt/hostedtoolcache/CodeQL || true
    sudo apt-get clean
    df -h /
fi

sudo apt-get update
"${APT_INSTALL[@]}" \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    git \
    libssl-dev \
    ninja-build \
    pkg-config \
    python3 \
    python3-boto3 \
    python3-zstandard
