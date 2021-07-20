#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-run.sh
#
# This script performs a `helm install` of all charts in the repository and runs
# the chart tests for each of them.
#
# Note: This script assumes you've created an environment with the adjacent
#       script "test-env.sh" and have a running Kubernetes cluster configured in
#       your local environment.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

if [[ -z $TEST_ENV_NAME ]]
then
    TEST_ENV_NAME="kong-charts-tests"
fi

if [[ ! -z $1 ]]
then
    CLEANUP_ONLY="true"
else
    CLEANUP_ONLY="false"
fi

# ------------------------------------------------------------------------------
# Shell Configuration
# ------------------------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------------------------
# Kubernetes Cluster Setup
# ------------------------------------------------------------------------------

kubectl cluster-info --context kind-${TEST_ENV_NAME} 1>/dev/null
KUBERNETES_VERSION="$(kubectl version -o json | jq -r '.serverVersion.gitVersion')"

# ------------------------------------------------------------------------------
# Setup Chart Cleanup - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

RELEASE_NAME="chart-tests"
RELEASE_NAMESPACE="$(uuidgen)"

function cleanup() {
    echo "INFO: cleaning up helm release ${RELEASE_NAME}"
    helm delete --namespace ${RELEASE_NAMESPACE} ${RELEASE_NAME}
    kubectl delete namespace ${RELEASE_NAMESPACE}
    kubectl delete clusterrole ${RELEASE_NAME}-kong
    exit 1
}

trap cleanup SIGINT SIGKILL

# ------------------------------------------------------------------------------
# Deploy Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

cd charts/kong/
echo "INFO: installing chart as release ${RELEASE_NAME} to namespace ${RELEASE_NAMESPACE}"
helm install --create-namespace --namespace ${RELEASE_NAMESPACE} ${RELEASE_NAME} ./

# ------------------------------------------------------------------------------
# Test Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

echo "INFO: running helm tests for all charts on Kubernetes ${KUBERNETES_VERSION}"
helm test --namespace ${RELEASE_NAMESPACE} ${RELEASE_NAME}
