#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# TAG=<OPTIONAL TAG> ./test-upgrade.sh
#
# This script (by default) tests against the `next` branch of the KIC to ensure
# that chart upgrades work against the latest work being done there.
#
# Optionally, the script can be flagged to test upgrades from the current default
# tag (provided by the chart and values.yaml) to any tag specified.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"
TAG="${TAG:-next-railgun}"
RELEASE_NAME="${RELEASE_NAME:-chart-tests-upgrade-compat}"
RELEASE_NAMESPACE="${RELEASE_NAMESPACE:-$(uuidgen)}"

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
# Upgrade Chart Image
# ------------------------------------------------------------------------------

echo "INFO: upgrading the helm chart to image tag ${TAG}"
helm upgrade --namespace ${RELEASE_NAMESPACE} --set ingressController.image.tag=${TAG} ${RELEASE_NAME} ./

# ------------------------------------------------------------------------------
# Test Upgraded Chart
# ------------------------------------------------------------------------------

echo "INFO: running helm tests for all charts on Kubernetes ${KUBERNETES_VERSION}"
helm test --namespace ${RELEASE_NAMESPACE} ${RELEASE_NAME}
