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
RELEASE_NAMESPACE="${RELEASE_NAMESPACE:-$(uuidgen)}"
TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"
KUBECTL="kubectl --context kind-${TEST_ENV_NAME}"
KUBERNETES_VERSION="$($KUBECTL version -o json | jq -r '.serverVersion.gitVersion')"

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

if [[ "${TAG}" == "default" ]]
then
    echo "INFO: installing chart as release ${RELEASE_NAME} to namespace ${RELEASE_NAMESPACE}"
    helm install --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" \
        --set deployment.test.enabled=true \
		--set ingressController.env.feature_gates="Gateway=true" \
		charts/kong/
else
    echo "INFO: installing chart as release ${RELEASE_NAME} with controller tag ${TAG} to namespace ${RELEASE_NAMESPACE}"
    helm install --namespace "${RELEASE_NAMESPACE}" \
        --set ingressController.image.tag="${TAG}" "${RELEASE_NAME}" --set deployment.test.enabled=true charts/kong/
fi

# ------------------------------------------------------------------------------
# Test Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

echo "INFO: running helm tests for all charts on Kubernetes ${KUBERNETES_VERSION}"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"

# ------------------------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------------------------
helm delete --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
