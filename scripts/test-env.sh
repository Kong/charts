#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-env.sh
#
# This script is used predominantly by CI in order to deploy a testing environment
# for running the chart tests in this repository. The testing environment includes
# a fully functional Kubernetes cluster, usually based on a local Kubernetes
# distribution like Kubernetes in Docker (KIND).
#
# Note: Callers are responsible for cleaning up after themselves, the testing env
#       created here can be torn down with `ktf environments delete --name <NAME>`.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"
if [[ -n $1 ]]
then
    if [[ "$1" == "cleanup" ]]
    then
        ktf environments delete --name "${TEST_ENV_NAME}"
        exit $?
    fi
fi

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}/.."
KIND_VERSION="${KIND_VERSION:-v0.17.0}"
KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.26.0}"

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
    go install sigs.k8s.io/kind@"${KIND_VERSION}"
fi

# ensure kind is functional
kind version 1>/dev/null

# ------------------------------------------------------------------------------
# Setup Tools - KTF
# ------------------------------------------------------------------------------

# ensure ktf command is accessible
if ! command -v ktf 1>/dev/null
then
    mkdir -p "${HOME}"/.local/bin
    GOBIN="${HOME}"/.local/bin go install github.com/kong/kubernetes-testing-framework/cmd/ktf@latest
    export PATH="${HOME}/.local/bin:$PATH"
fi

# ensure kind is functional
ktf 1>/dev/null

# ------------------------------------------------------------------------------
# Create Testing Environment
# ------------------------------------------------------------------------------

ktf environments create --name "${TEST_ENV_NAME}" --addon metallb --addon kuma --kubernetes-version ${KUBERNETES_VERSION}

kubectl kustomize "github.com/kubernetes-sigs/gateway-api/config/crd/experimental?ref=v0.5.1" | kubectl apply -f -

echo "INFO: Updating helm dependencies"
helm dependency update charts/kong/
