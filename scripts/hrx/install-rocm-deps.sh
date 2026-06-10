#!/usr/bin/env bash
set -euo pipefail

# Self-hosted runners execute jobs in containers as root with no sudo.
maybe_sudo() {
    if [[ "$(id -u)" == "0" ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Reclaim disk space on GitHub-hosted runners only; these paths belong to the
# hosted image and must not be removed on self-hosted runners.
if [[ "${GITHUB_ACTIONS:-}" == "true" && "${RUNNER_ENVIRONMENT:-}" == "github-hosted" ]]; then
    df -h /
    maybe_sudo rm -rf /usr/share/dotnet /usr/local/lib/android /opt/ghc /usr/local/share/boost /opt/hostedtoolcache/CodeQL || true
    maybe_sudo apt-get clean
    df -h /
fi

maybe_sudo apt-get update
maybe_sudo apt-get install -y --no-install-recommends \
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
