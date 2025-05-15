#!/usr/bin/env bash

# This script generates RBAC resource templates based on KGO and KGO EE manifests.
# It accepts the following arguments:
# $1: the path to the kgo repository
# $2: the path to the kgo ee repository
# $3: the path to the kong/charts repository

set -euo pipefail

ARGS_N=3

if [ "$#" -ne ${ARGS_N} ]; then
  echo "Error: You must provide exactly ${ARGS_N} arguments."
  exit 1
fi

KGO_REPO_PATH="${1}"
KGOEE_REPO_PATH="${2}"
CHARTS_REPO_PATH="${3}"

SED="sed"
if [[ $(uname -s) == "Darwin" ]]; then
  if gsed --version >/dev/null 2>&1 ; then
    SED="gsed"
  else
    echo "GNU sed is required on macOS. You can install it via Homebrew with 'brew install gnu-sed'."
    exit 1
  fi
fi

function require_var_dir() {
  if [[ -z "${!1}" ]]
  then
    echo "\$${1} is required"
    exit 1
  fi

  if [[ ! -d "${!1}" ]]
  then
    echo "\$${1} (current value: ${!1}) needs to be a directory"
    exit 1
  fi
}

function update_rbac_resources {
  local TMPFILE
  TMPFILE=$(mktemp).yaml

  # build the kustomize resources
  kustomize build "${KGOEE_REPO_PATH}/config/rbac" > "${TMPFILE}"
  echo "---" >> "${TMPFILE}"
  kustomize build "${KGO_REPO_PATH}/config/rbac/base" >> "${TMPFILE}"

  # copy the contents of the file except for the Service Account resource
  yq --inplace e ". | select(.kind != \"ServiceAccount\")" "${TMPFILE}"

  # replace the namespace
  ${SED} -i 's/namespace: kong-system/namespace: {{ template "kong.namespace" . }}/g' "${TMPFILE}"

  # replace the service account name
  ${SED} -i 's/name: controller-manager$/name: {{ template "kong.serviceAccountName" . }}/g' "${TMPFILE}"

  # replace the role name
  ${SED} -i 's/name: gateway-operator-manager-role/name: {{ template "kong.fullname" . }}-manager-role/g' "${TMPFILE}"

  # replace the metrics service name
  ${SED} -i 's/name: controller-manager-metrics-service/name: {{ template "kong.fullname" . }}-metrics-service/g' "${TMPFILE}"

  # replace the name of the resources
  ${SED} -i '/name: {{\|name: https/!s/name: /name: {{ template "kong.fullname" . }}-/g' "${TMPFILE}"

  # move the new file to the charts directory
  mv "${TMPFILE}" "${CHARTS_REPO_PATH}/charts/gateway-operator/templates/rbac-resources.yaml"
}

require_var_dir KGOEE_REPO_PATH
require_var_dir KGO_REPO_PATH
require_var_dir CHARTS_REPO_PATH
# call the update_rbac_resources function
update_rbac_resources

