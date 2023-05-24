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
# Configuration
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}/.."

TAG="${TAG:-default}"
RELEASE_NAME="${RELEASE_NAME:-chart-tests}"
RELEASE_NAMESPACE="${RELEASE_NAMESPACE:-$(uuidgen | tr "[:upper:]" "[:lower:]")}"
TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"
KUBECTL="kubectl --context kind-${TEST_ENV_NAME}"
KUBERNETES_VERSION="$($KUBECTL version -o json | jq -r '.serverVersion.gitVersion')"

CONTROLLER_PREFIX=""
ADDITIONAL_FLAGS=()

# ------------------------------------------------------------------------------
# Configure per-chart settings
# ------------------------------------------------------------------------------
if [[ "${CHART_NAME}" == "ingress" ]]; then
  CONTROLLER_PREFIX="controller."
  ADDITIONAL_FLAGS+=("--set ${CONTROLLER_PREFIX}ingressController.gatewayDiscovery.adminApiService.name=${RELEASE_NAME}-gateway-admin ")
fi

# ------------------------------------------------------------------------------
# Deploy Kuma configuration and test namespace
# ------------------------------------------------------------------------------

echo "---
apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    backends:
    - conf:
        caCert:
          RSAbits: 2048
          expiration: 10y
      dpCert:
        rotation:
          expiration: 1d
      name: ca-1
      type: builtin
    enabledBackend: ca-1
---
apiVersion: v1
kind: Namespace
metadata:
  labels:
    kuma.io/sidecar-injection: enabled
  name: ${RELEASE_NAMESPACE}
" | kubectl --context "kind-${TEST_ENV_NAME}" apply -f -

# ------------------------------------------------------------------------------
# Deploy Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

TAG_MESSAGE=""
if [[ "${TAG}" != "default" ]]
then
  TAG_MESSAGE="with controller tag ${TAG} "
  ADDITIONAL_FLAGS+=("--set ${CONTROLLER_PREFIX}ingressController.image.tag=${TAG} ");
fi

# Configure values for all tests
# Enable Gateway API
ADDITIONAL_FLAGS+=("--set ${CONTROLLER_PREFIX}ingressController.env.feature_gates=GatewayAlpha=true")
# Tests should not show up in reporting
ADDITIONAL_FLAGS+=("--set ${CONTROLLER_PREFIX}ingressController.env.anonymous_reports=false")

echo "INFO: installing chart as release ${RELEASE_NAME} ${TAG_MESSAGE}to namespace ${RELEASE_NAMESPACE}"
set -x
# shellcheck disable=SC2048,SC2086
helm install --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" \
    --set deployment.test.enabled=true \
    ${ADDITIONAL_FLAGS[*]} \
    "charts/${CHART_NAME}"
set +x

# ------------------------------------------------------------------------------
# Test Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

echo "INFO: running helm tests for ${CHART_NAME} chart on Kubernetes ${KUBERNETES_VERSION}"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------
helm delete --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
