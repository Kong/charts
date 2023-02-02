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
# Configuration
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}/.."

TAG="${TAG:-next-railgun}"
EFFECTIVE_TAG="2.0.0"
RELEASE_NAME="${RELEASE_NAME:-chart-tests-upgrade-compat}"
RELEASE_NAMESPACE="${RELEASE_NAMESPACE:-$(uuidgen)}"
TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"
KUBECTL="kubectl --context kind-${TEST_ENV_NAME}"
KUBERNETES_VERSION="$($KUBECTL version -o json | jq -r '.serverVersion.gitVersion')"

# ------------------------------------------------------------------------------
# Deploy Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

echo "INFO: installing chart as release ${RELEASE_NAME} to namespace ${RELEASE_NAMESPACE}"
helm install --create-namespace --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" \
    --set ingressController.env.anonymous_reports="false" \
    --set deployment.test.enabled=true \
    charts/kong/

# ------------------------------------------------------------------------------
# Test Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

echo "INFO: running helm tests for all charts on Kubernetes ${KUBERNETES_VERSION}"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"

# ------------------------------------------------------------------------------
# Upgrade Chart Image
# ------------------------------------------------------------------------------

echo "INFO: upgrading the helm chart to image tag ${TAG}"
helm upgrade --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" \
    --set ingressController.image.tag="${TAG}" \
    --set deployment.test.enabled=true \
    --set ingressController.env.anonymous_reports="false" \
    --set ingressController.image.effectiveSemver="${EFFECTIVE_TAG}" \
    charts/kong/

# ------------------------------------------------------------------------------
# Test Upgraded Chart
# ------------------------------------------------------------------------------

echo "INFO: running helm tests for all charts on Kubernetes ${KUBERNETES_VERSION}"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"


# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------
helm delete --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
