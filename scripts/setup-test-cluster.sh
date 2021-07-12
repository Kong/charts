#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

if [[ -z $TEST_ENV_NAME ]]
then
    TEST_ENV_NAME="kong-charts-tests"
fi

if [[ -z $KIND_VERSION ]]
then
    KIND_VERSION="v0.11.1"
fi

# ------------------------------------------------------------------------------
# Shell Configuration
# ------------------------------------------------------------------------------

set -eu

# ------------------------------------------------------------------------------
# Setup Tools - Docker
# ------------------------------------------------------------------------------

# ensure docker command is accessible
if ! command -v docker &> /dev/null
then
    echo "ERROR: docker command not found"
    exit 10
fi

# ensure docker is functional
docker info 1>/dev/null

# ------------------------------------------------------------------------------
# Setup Tools - Kind
# ------------------------------------------------------------------------------

# ensure kind command is accessible
if ! command -v kind &> /dev/null
then
    go get -v sigs.k8s.io/kind@${KIND_VERSION}
fi

# ensure kind is functional
kind version 1>/dev/null

# ------------------------------------------------------------------------------
# Setup Tools - KTF
# ------------------------------------------------------------------------------

# ensure ktf command is accessible
if ! command -v ktf 1>/dev/null
then
    mkdir -p ${HOME}/.local/bin
    curl --proto '=https' -sSf https://kong.github.io/kubernetes-testing-framework/install.sh | sh
    export PATH="${HOME}/.local/bin:$PATH"
fi

# ensure kind is functional
ktf 1>/dev/null

# ------------------------------------------------------------------------------
# Configure Cleanup
# ------------------------------------------------------------------------------

function cleanup() {
    ktf environments delete --name ${TEST_ENV_NAME}
    exit 1
}

trap cleanup SIGTERM SIGINT EXIT

# ------------------------------------------------------------------------------
# Create Testing Environment
# ------------------------------------------------------------------------------

ktf environments create --name ${TEST_ENV_NAME} --addon metallb
