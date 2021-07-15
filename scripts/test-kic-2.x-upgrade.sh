#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-kick-2.x-upgrade.sh
#
# This script is temporary: in the timeframe between 1.x and 2.x KIC
# releases this script was made to validate that upgrading to the
# latest pre-release image was functional, once 2.0 releases fully
# this script will be removed because all tests thereafter will be
# running on that version and it's lineage.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

if [[ -z $TEST_ENV_NAME ]]
then
    TEST_ENV_NAME="kong-charts-tests"
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
# Determine the latest KIC 2.x Pre-Release Version
# ------------------------------------------------------------------------------

BASE="kong/kubernetes-ingress-controller"
LATEST_PRERELEASE=$(curl -s https://api.github.com/repos/${BASE}/releases | \
    jq -r '.[] | select(.tag_name | test("^2.[0-9]+.[0-9]+")) | .name' | head -1)

if [ "$LATEST_PRERELEASE" = "" ]; then
    echo "Error: could not find latest release for ${BASE}!${LATEST_PRERELEASE}"
    exit 1
fi

echo "INFO: the latest release of ${BASE} v2.x was determined to be ${LATEST_PRERELEASE}"

# ------------------------------------------------------------------------------
# Setup Chart Cleanup - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

RELEASE_NAME="chart-tests-prerelease-compat"
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

# ------------------------------------------------------------------------------
# Upgrade Chart Image To v2.x
# ------------------------------------------------------------------------------

echo "INFO: upgrading the helm chart to latest pre-release image ${LATEST_PRERELEASE}"
helm upgrade --namespace ${RELEASE_NAMESPACE} --set ingressController.image.tag=${LATEST_PRERELEASE} ${RELEASE_NAME} ./

# ------------------------------------------------------------------------------
# Test Upgraded Chart
# ------------------------------------------------------------------------------

echo "INFO: running helm tests for all charts on Kubernetes ${KUBERNETES_VERSION}"
helm test --namespace ${RELEASE_NAMESPACE} ${RELEASE_NAME}
