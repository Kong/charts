#!/usr/bin/env bash

set -euo pipefail

if [ -z "${CHARTSNAP_VERSION}" ]; then
  echo "ERROR: CHARTSNAP_VERSION is not set"
  exit 1
fi

if [ -z "${HELM}" ]; then
  echo "ERROR: HELM is not set"
  exit 1
fi

HELM_VERSION_MAJOR=$(${HELM} version --template='{{.Version}}' | sed -E 's/^v([0-9]+)\..*/\1/')
HELM_PLUGIN_INSTALL_OPTS=""
if [ "${HELM_VERSION_MAJOR}" -eq 4 ]; then
  HELM_PLUGIN_INSTALL_OPTS="--verify=false"
fi

echo "INFO: Helm version detected: ${HELM_VERSION_MAJOR}"

# Only install the plugin if it is not already installed or if the version is different.
if [[ $(${HELM} plugin list | grep chartsnap | grep -Eo '[0-9]{1,}.[0-9]{1,}.[0-9]{1,}') == "${CHARTSNAP_VERSION}" ]]; then
  echo "INFO: chartsnap plugin is already installed and up to date"
else
  echo "INFO: Installing chartsnap plugin"
  if [ "$(${HELM} plugin list | grep -ic chartsnap)" -eq 1 ]; then
    echo "INFO: Uninstalling existing chartsnap plugin - version mismatch"
    ${HELM} plugin uninstall chartsnap
  fi
  ${HELM} plugin install ${HELM_PLUGIN_INSTALL_OPTS} \
    https://github.com/jlandowner/helm-chartsnap \
    --version "${CHARTSNAP_VERSION}"
fi
