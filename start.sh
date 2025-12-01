#!/bin/bash
set -e

# Validate required environment variables
if [ -z "${GH_TOKEN}" ]; then
    echo "Error: GH_TOKEN is not set. Please provide a GitHub Personal Access Token."
    exit 1
fi

if [ -z "${GH_OWNER}" ]; then
    echo "Error: GH_OWNER is not set. Please provide the GitHub owner (username or organization)."
    exit 1
fi

# Determine registration type (repo or org level)
if [ -n "${GH_REPOSITORY}" ]; then
    # Repository level registration
    REGISTRATION_URL="https://github.com/${GH_OWNER}/${GH_REPOSITORY}"
    TOKEN_URL="https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/registration-token"
    echo "Registering runner for repository: ${GH_OWNER}/${GH_REPOSITORY}"
else
    # Organization level registration
    REGISTRATION_URL="https://github.com/${GH_OWNER}"
    TOKEN_URL="https://api.github.com/orgs/${GH_OWNER}/actions/runners/registration-token"
    echo "Registering runner for organization: ${GH_OWNER}"
fi

# Get registration token
echo "Obtaining registration token..."
RUNNER_TOKEN=$(curl -s -X POST \
    -H "Authorization: token ${GH_TOKEN}" \
    -H "Accept: application/vnd.github.v3+json" \
    "${TOKEN_URL}" | jq -r '.token')

if [ -z "${RUNNER_TOKEN}" ] || [ "${RUNNER_TOKEN}" == "null" ]; then
    echo "Error: Failed to obtain registration token. Check your GH_TOKEN permissions."
    exit 1
fi

# Set runner name (default to hostname if not provided)
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"

# Set runner labels (default if not provided)
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,Linux,X64,docker}"

# Set runner work directory
RUNNER_WORKDIR="${RUNNER_WORKDIR:-_work}"

# Set runner group (only for org runners)
RUNNER_GROUP="${RUNNER_GROUP:-Default}"

# Configure the runner
echo "Configuring runner..."
./config.sh \
    --url "${REGISTRATION_URL}" \
    --token "${RUNNER_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --work "${RUNNER_WORKDIR}" \
    --runnergroup "${RUNNER_GROUP}" \
    --unattended \
    --replace \
    --ephemeral

# Cleanup function for graceful shutdown
cleanup() {
    echo "Removing runner..."
    # Get removal token
    if [ -n "${GH_REPOSITORY}" ]; then
        REMOVE_TOKEN_URL="https://api.github.com/repos/${GH_OWNER}/${GH_REPOSITORY}/actions/runners/remove-token"
    else
        REMOVE_TOKEN_URL="https://api.github.com/orgs/${GH_OWNER}/actions/runners/remove-token"
    fi
    
    REMOVE_TOKEN=$(curl -s -X POST \
        -H "Authorization: token ${GH_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        "${REMOVE_TOKEN_URL}" | jq -r '.token')
    
    if [ -n "${REMOVE_TOKEN}" ] && [ "${REMOVE_TOKEN}" != "null" ]; then
        ./config.sh remove --token "${REMOVE_TOKEN}"
    fi
}

# Set up signal handlers
trap 'cleanup; exit 0' SIGINT SIGTERM

echo "Starting runner..."
./run.sh &

# Wait for runner process
wait $!
