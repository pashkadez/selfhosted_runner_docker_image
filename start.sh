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
# Check environment variables first (highest priority)
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
fi

# If still not found, check for ARC-injected file paths (common locations)
# ARC sometimes mounts JIT config in _diag directory
if [[ -z "${JIT_CONFIG_FILE}" ]]; then
    JIT_CONFIG_FILE=$(find /actions-runner/_diag -name "jitconfig.json" -type f 2>/dev/null | head -1)
    if [[ -z "${JIT_CONFIG_FILE}" ]]; then
        # Try alternative location
        JIT_CONFIG_FILE=$(find /home/runner/_diag -name "jitconfig.json" -type f 2>/dev/null | head -1)
    fi
    if [[ -n "${JIT_CONFIG_FILE}" && -f "${JIT_CONFIG_FILE}" ]]; then
        echo "[entrypoint] Found ARC JIT config at: ${JIT_CONFIG_FILE}"
    else
        JIT_CONFIG_FILE=""
    fi
fi

# If still not found, check for ACTIONS_RUNNER_INPUT_JITCONFIG (ARC environment variable)
if [[ -z "${JIT_CONFIG_FILE}" && -n "${ACTIONS_RUNNER_INPUT_JITCONFIG:-}" ]]; then
    if [[ -f "${ACTIONS_RUNNER_INPUT_JITCONFIG}" ]]; then
        JIT_CONFIG_FILE="${ACTIONS_RUNNER_INPUT_JITCONFIG}"
        echo "[entrypoint] Using ACTIONS_RUNNER_INPUT_JITCONFIG file: ${JIT_CONFIG_FILE}"
    elif echo -n "${ACTIONS_RUNNER_INPUT_JITCONFIG}" | base64 -d > /dev/null 2>&1; then
        # Try decoding as base64
        JIT_CONFIG_FILE="/home/runner/jitconfig.json"
        echo "[entrypoint] Decoding ACTIONS_RUNNER_INPUT_JITCONFIG (base64) into ${JIT_CONFIG_FILE}"
        echo -n "${ACTIONS_RUNNER_INPUT_JITCONFIG}" | base64 -d > "${JIT_CONFIG_FILE}"
    else
        # Assume it's a JSON string
        JIT_CONFIG_FILE="/home/runner/jitconfig.json"
        echo "[entrypoint] Writing ACTIONS_RUNNER_INPUT_JITCONFIG to ${JIT_CONFIG_FILE}"
        echo -n "${ACTIONS_RUNNER_INPUT_JITCONFIG}" > "${JIT_CONFIG_FILE}"
    fi
fi

if [[ -z "${JIT_CONFIG_FILE}" || ! -f "${JIT_CONFIG_FILE}" ]]; then
    echo "[entrypoint] ERROR: No JIT config found." >&2
    echo "[entrypoint] Checked:" >&2
    echo "[entrypoint]   - RUNNER_JIT_CONFIG=${RUNNER_JIT_CONFIG:-unset}" >&2
    echo "[entrypoint]   - RUNNER_JIT_CONFIG_BASE64=${RUNNER_JIT_CONFIG_BASE64:+set}" >&2
    echo "[entrypoint]   - RUNNER_JIT_CONFIG_PATH=${RUNNER_JIT_CONFIG_PATH:-unset}" >&2
    echo "[entrypoint]   - ACTIONS_RUNNER_INPUT_JITCONFIG=${ACTIONS_RUNNER_INPUT_JITCONFIG:+set}" >&2
    echo "[entrypoint]   - /actions-runner/_diag/*/jitconfig.json" >&2
    echo "[entrypoint]   - /home/runner/_diag/*/jitconfig.json" >&2
    echo "[entrypoint] Environment variables:" >&2
    env | sort | sed 's/^/[env] /'
    echo "[entrypoint] Searching for jitconfig files:" >&2
    find /actions-runner /home/runner -name "*jitconfig*" -type f 2>/dev/null | head -10 | sed 's/^/[search] /' || true
    exit 1
fi

for v in RUNNER_NAME RUNNER_LABELS RUNNER_ASSETS_DIR RUNNER_WORKDIR; do
    if [[ -n "${!v:-}" ]]; then echo "[entrypoint] ${v}=${!v}"; fi
done

echo "[entrypoint] Starting Runner.Listener with JIT config"
exec ./bin/Runner.Listener run --jitconfig "${JIT_CONFIG_FILE}" --work "$RUNNER_WORKDIR" --once
