#!/usr/bin/env bash
set -euo pipefail

# ARC-compatible entrypoint for ephemeral runners.
# Expects ARC to inject JIT config secret and envs.

echo "[entrypoint] uname: $(uname -a)"
echo "[entrypoint] user: $(id)"
echo "[entrypoint] runner dir (initial): $PWD"
echo "[entrypoint] actions runner version: ${RUNNER_VERSION:-unknown}"

if [[ ! -x ./bin/Runner.Listener ]]; then
    for candidate in /actions-runner /home/runner/actions-runner; do
        if [[ -x "${candidate}/bin/Runner.Listener" ]]; then
            echo "[entrypoint] Switching to ${candidate}"
            cd "${candidate}"
            break
        fi
    done
fi

if [[ ! -x ./bin/Runner.Listener ]]; then
    echo "[entrypoint] ERROR: Runner binaries missing at ./bin/Runner.Listener" >&2
    ls -la ./bin || true
    exit 1
fi

echo "[entrypoint] runner dir (resolved): $PWD"
export RUNNER_ASSETS_DIR=${RUNNER_ASSETS_DIR:-$PWD}

export RUNNER_WORKDIR=${RUNNER_WORKDIR:-_work}
mkdir -p "$RUNNER_WORKDIR"

JIT_CONFIG_FILE=""
if [[ -n "${RUNNER_JIT_CONFIG:-}" && -f "${RUNNER_JIT_CONFIG}" ]]; then
    JIT_CONFIG_FILE="${RUNNER_JIT_CONFIG}"
    echo "[entrypoint] Using RUNNER_JIT_CONFIG file: ${JIT_CONFIG_FILE}"
elif [[ -n "${RUNNER_JIT_CONFIG_BASE64:-}" ]]; then
    JIT_CONFIG_FILE="/home/runner/jitconfig.json"
    echo "[entrypoint] Decoding RUNNER_JIT_CONFIG_BASE64 into ${JIT_CONFIG_FILE}"
    echo -n "${RUNNER_JIT_CONFIG_BASE64}" | base64 -d > "${JIT_CONFIG_FILE}"
elif [[ -n "${RUNNER_JIT_CONFIG_PATH:-}" && -f "${RUNNER_JIT_CONFIG_PATH}" ]]; then
    JIT_CONFIG_FILE="${RUNNER_JIT_CONFIG_PATH}"
    echo "[entrypoint] Using RUNNER_JIT_CONFIG_PATH file: ${JIT_CONFIG_FILE}"
else
    echo "[entrypoint] ERROR: No JIT config env found (RUNNER_JIT_CONFIG or RUNNER_JIT_CONFIG_BASE64 or RUNNER_JIT_CONFIG_PATH)." >&2
    env | sort | sed 's/^/[env] /'
    exit 1
fi

for v in RUNNER_NAME RUNNER_LABELS RUNNER_ASSETS_DIR RUNNER_WORKDIR; do
    if [[ -n "${!v:-}" ]]; then echo "[entrypoint] ${v}=${!v}"; fi
done

echo "[entrypoint] Starting Runner.Listener with JIT config"
exec ./bin/Runner.Listener run --jitconfig "${JIT_CONFIG_FILE}" --work "$RUNNER_WORKDIR" --once
