#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-crds.sh
#
# This script tests that our legacy v1beta1 versions of our CRDs upgrade cleanly
# to their v1 versions, and that both the legacy and the v1 versions of the CRDs
# both function with our controllers.
#
# NOTE: these tests are sensitive to which Kubernetes version they are run on.
#       they will only run on Kubernetes clusters between v1.16.x and 1.21.x
#       (inclusively) as v1.15.x is too old for the new CRDs and v1.22.x is to new
#       for the old CRDs. At some point in the future (potentially when <v1.22.x is
#       no longer supported by the chart) we can remove these tests.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}/.."

LEGACY_CRD_KIC_TAG="${LEGACY_CRD_KIC_TAG:-1.3.1}"
RELEASE_NAME="${RELEASE_NAME:-chart-tests-crds}"
RELEASE_NAMESPACE="${RELEASE_NAMESPACE:-$(uuidgen)}"
TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"
KUBECTL="kubectl --context kind-${TEST_ENV_NAME}"
KUBERNETES_VERSION="$($KUBECTL version -o json | jq -r '.serverVersion.gitVersion')"

echo "INFO: running CRD tests on Kubernetes ${KUBERNETES_VERSION}"

# ------------------------------------------------------------------------------
# Cleanup Existing CRDs and Deploy Legacy CRDs
# ------------------------------------------------------------------------------

echo "INFO: cleaning up existing CRDs from the test cluster"
EXISTING_CRDS=$($KUBECTL get crds -o=go-template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' |grep 'konghq.com')
# shellcheck disable=SC2086
$KUBECTL delete crds ${EXISTING_CRDS}

echo "INFO: deploying legacy CRDs from KIC version ${LEGACY_CRD_KIC_TAG}"
$KUBECTL apply -f "https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/${LEGACY_CRD_KIC_TAG}/deploy/manifests/base/custom-types.yaml"

# ------------------------------------------------------------------------------
# Deploy Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

echo "INFO: installing chart as release ${RELEASE_NAME} to namespace ${RELEASE_NAMESPACE}"
helm install --create-namespace --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" \
    --set deployment.test.enabled=true charts/kong/

# ------------------------------------------------------------------------------
# Test Chart - Legacy CRDs
# ------------------------------------------------------------------------------

echo "INFO: validating that Helm did not update the CRDs (this must be done manually after initial deploy)"
CRD_GENERATION=$($KUBECTL get crds tcpingresses.configuration.konghq.com -o=go-template='{{.metadata.generation}}')
if [[ ${CRD_GENERATION} -gt 1 ]]
then
    echo "ERROR: CRDs got unexpectedly updated automatically by the Helm chart install"
    exit 1
fi

echo "INFO: running helm tests for all charts using legacy CRDs"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"

# ------------------------------------------------------------------------------
# Test Chart - V1 CRDs
# ------------------------------------------------------------------------------

echo "INFO: cleaning up previous chart to ensure a fresh test with updated CRDs"
helm delete --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
$KUBECTL delete namespace "${RELEASE_NAMESPACE}"

echo "INFO: updating CRDs to version 1"
$KUBECTL apply -f charts/kong/crds/custom-resource-definitions.yaml

CRD_GENERATION=$($KUBECTL get crds tcpingresses.configuration.konghq.com -o=go-template='{{.metadata.generation}}')
if [[ ${CRD_GENERATION} -lt 2 ]]
then
    echo "ERROR: CRDs were not updated properly"
    exit 1
fi

echo "INFO: re-installing chart as release ${RELEASE_NAME} to namespace ${RELEASE_NAMESPACE}"
helm install --create-namespace --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" \
    --set deployment.test.enabled=true charts/kong/

echo "INFO: running helm tests for all charts using V1 CRDs"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
