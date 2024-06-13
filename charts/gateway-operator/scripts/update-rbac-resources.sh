#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# 
# cd kong/gateway-operator/config 
# kustomize build rbac > /tmp/rbac-resources.yaml
# sed -i 's/namespace: kong-system/namespace: {{ template "kong.namespace" . }}/g' /tmp/rbac-resources.yaml
# sed -i 's/name: controller-manager$/name: {{ template "kong.serviceAccountName" . }}/g' /tmp/rbac-resources.yaml
# sed -i 's/name: gateway-operator-manager-role/name: {{ template "kong.fullname" . }}-manager-role/g' /tmp/rbac-resources.yaml
# sed -i 's/name: controller-manager-metrics-service/name: {{ template "kong.fullname" . }}-metrics-service/g' /tmp/rbac-resources.yaml
# Then copy the contents of this file except for the Service Account resource using the following command
# (head -n 11 PATH_OF_YOUR_CHARTS_REPO/charts/gateway-operator/templates/rbac-resources.yaml && tail -n +6 /tmp/rbac-resources.yaml) > /tmp/new-rbac-resources.yaml
# mv /tmp/new-rbac-resources.yaml YOUR-PATH-OF-CHARTS/charts/gateway-operator/templates/rbac-resources.yaml
# ------------------------------------------------------------------------------

# this script will receive two arguments:
# $1: the path to the kgo repository
# $2: the path to the kong/charts repository

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Error: You must provide exactly two arguments."
  exit 1
fi

KGO_REPO_PATH=$1
CHARTS_REPO_PATH=$2

# check if the kgo repository path is empty
if [ -z "$KGO_REPO_PATH" ]
then
  echo "The path to the kgo repository is required"
  exit 1
fi

# check if the kong/charts repository path is empty
if [ -z "$CHARTS_REPO_PATH" ]
then
  echo "The path to the kong/charts repository is required"
  exit 1
fi

SED=sed
if [[ $(uname -s) == "Darwin" ]]; then
  if gsed --version 2>&1 >/dev/null ; then
    SED=gsed
  else
    echo "GNU sed is required on macOS. You can install it via Homebrew with 'brew install gnu-sed'."
    exit 1
  fi
fi

# create a function named update_rbac_resources
function update_rbac_resources {
  # build the kustomize resources
  kustomize build $KGO_REPO_PATH/config/rbac > /tmp/rbac-resources.yaml

  # replace the namespace
  ${SED} -i 's/namespace: kong-system/namespace: {{ template "kong.namespace" . }}/g' /tmp/rbac-resources.yaml

  # replace the service account name
  ${SED} -i 's/name: controller-manager$/name: {{ template "kong.serviceAccountName" . }}/g' /tmp/rbac-resources.yaml

  # replace the role name
  ${SED} -i 's/name: gateway-operator-manager-role/name: {{ template "kong.fullname" . }}-manager-role/g' /tmp/rbac-resources.yaml

  # replace the metrics service name
  ${SED} -i 's/name: controller-manager-metrics-service/name: {{ template "kong.fullname" . }}-metrics-service/g' /tmp/rbac-resources.yaml

  # replace the name of the resources
  ${SED} -i '/name: {{\|name: https/!s/name: /name: {{ template "kong.fullname" . }}-/g' /tmp/rbac-resources.yaml

  # copy the contents of the file except for the Service Account resource
  (head -n 4 $CHARTS_REPO_PATH/charts/gateway-operator/templates/rbac-resources.yaml && tail -n +6 /tmp/rbac-resources.yaml) > /tmp/new-rbac-resources.yaml

  # move the new file to the charts directory
  mv /tmp/new-rbac-resources.yaml $CHARTS_REPO_PATH/charts/gateway-operator/templates/rbac-resources.yaml
}

# call the update_rbac_resources function
update_rbac_resources

