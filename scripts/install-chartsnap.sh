#!/usr/bin/env bash

if [ -z "${CHARTSNAP_VERSION}" ]; then
  echo "ERROR: CHARTSNAP_VERSION is not set"
  exit 1
fi

# Only install the plugin if it is not already installed or if the version is different.
if [[ $(helm plugin list | grep chartsnap | grep -Eo '[0-9]{1,}.[0-9]{1,}.[0-9]{1,}') == "${CHARTSNAP_VERSION}" ]]; then
  echo "INFO: chartsnap plugin is already installed and up to date"
else
  echo "INFO: Installing chartsnap plugin"
  if [ "$(helm plugin list | grep -ic chartsnap)" -eq 1 ]; then
    echo "INFO: Uninstalling existing chartsnap plugin - version mismatch"
    helm plugin uninstall chartsnap
  fi
  helm plugin install https://github.com/jlandowner/helm-chartsnap --version "${CHARTSNAP_VERSION}"
fi
