#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-crds.sh
#
# This script tests that our legacy v1beta1 versions of our CRDs upgrade cleanly
# to their v1 versions, and that both the legacy and the v1 versions of the CRDs
# both function with our controllers.
#
# Test Workflow
#
#   Step 1
#
#   1. deploy the legacy CRDs
#   2. install the chart
#   3. verify legacy CRDs are in place
#   4. run helm tests (via legacy CRDs)
#
#   Step 2
#
#   1. cleanup the chart
#   2. deploy the v1 CRDs
#   3. verify the CRDs updates
#   4. redeploy the chart
#   5. run helm tests (via v1 CRDs)
#
# NOTE: these tests are sensitive to which Kubernetes version they are run on.
#       they will only run on Kubernetes clusters between v1.16.x and 1.21.x,
#       as v1.15.x is too old for the new CRDs and v1.22.x is to new for the
#       old CRDs. At some point in the future (potentially when <v1.22.x is no
#       longer supported by the chart) we can remove these tests.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"

set -euo pipefail

# ------------------------------------------------------------------------------
# Kubernetes Cluster Setup
# ------------------------------------------------------------------------------

kubectl cluster-info --context kind-"${TEST_ENV_NAME}" 1>/dev/null
KUBERNETES_VERSION="$(kubectl version -o json | jq -r '.serverVersion.gitVersion')"

echo "INFO: running CRD tests on Kubernetes ${KUBERNETES_VERSION}"

# ------------------------------------------------------------------------------
# Setup Chart Cleanup - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

RELEASE_NAME="chart-tests"
RELEASE_NAMESPACE="$(uuidgen)"

function cleanup() {
    echo "INFO: cleaning up helm release ${RELEASE_NAME}"
    helm delete --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
    kubectl delete namespace "${RELEASE_NAMESPACE}"
    kubectl delete clusterrole "${RELEASE_NAME}"-kong
    exit 1
}

trap cleanup SIGINT

# ------------------------------------------------------------------------------
# Cleanup CRDs
# ------------------------------------------------------------------------------

echo "INFO: cleaning up existing CRDs from the test cluster"
for CRD in $(kubectl get crds -o=go-template='{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' |grep 'konghq.com')
do
    kubectl delete crd "${CRD}"
done

# ------------------------------------------------------------------------------
# Deploy Legacy CRDs
# ------------------------------------------------------------------------------

LAST_CRD_UPDATE="d2442de89cc036843c5f552c7daa6b023405f365"
kubectl apply -f "https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/${LAST_CRD_UPDATE}/deploy/manifests/base/custom-types.yaml"

# ------------------------------------------------------------------------------
# Deploy Chart - Kubernetes Ingress Controller
# ------------------------------------------------------------------------------

cd charts/kong/
echo "INFO: installing chart as release ${RELEASE_NAME} to namespace ${RELEASE_NAMESPACE}"
helm install --create-namespace --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" ./

# ------------------------------------------------------------------------------
# Test Chart - Legacy CRDs
# ------------------------------------------------------------------------------

echo "INFO: validating that Helm did not update the CRDs (this must be done manually after initial deploy)"
CRD_GENERATION=$(kubectl get crds tcpingresses.configuration.konghq.com -o=go-template='{{.metadata.generation}}')
if [[ ${CRD_GENERATION} -gt 1 ]]
then
    echo "ERROR: CRDs got unexpectedly updated automatically by the Helm chart install"
    exit 1
fi

echo "INFO: running helm tests for all charts using legacy CRDs"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"

# ------------------------------------------------------------------------------
# Test Chart - Cleanup
# ------------------------------------------------------------------------------

echo "INFO: cleaning up previous chart to ensure a fresh test with updated CRDs"
helm delete --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
kubectl delete namespace "${RELEASE_NAMESPACE}"

# ------------------------------------------------------------------------------
# Test Chart - V1 CRDs
# ------------------------------------------------------------------------------

echo "INFO: updating CRDs to version 1"
kubectl apply -f ./crds/custom-resource-definitions.yaml

CRD_GENERATION=$(kubectl get crds tcpingresses.configuration.konghq.com -o=go-template='{{.metadata.generation}}')
if [[ ${CRD_GENERATION} -lt 2 ]]
then
    echo "ERROR: CRDs were not updated properly"
    exit 1
fi

echo "INFO: re-installing chart as release ${RELEASE_NAME} to namespace ${RELEASE_NAMESPACE}"
helm install --create-namespace --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}" ./

echo "INFO: running helm tests for all charts using V1 CRDs"
helm test --namespace "${RELEASE_NAMESPACE}" "${RELEASE_NAME}"
