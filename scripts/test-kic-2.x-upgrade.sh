#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-kic-2.x-upgrade.sh
#
# This script is temporary: in the timeframe between 1.x and 2.x KIC
# releases this script was made to validate that upgrading to the
# latest pre-release image was functional, once 2.0 releases fully
# this script will be removed because all tests thereafter will be
# running on that version and it's lineage.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------

TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"

# ------------------------------------------------------------------------------
# Shell Configuration
# ------------------------------------------------------------------------------

set -euo pipefail

# ------------------------------------------------------------------------------
# Determine the latest KIC 2.x Pre-Release Version
# ------------------------------------------------------------------------------

BASE="kong/kubernetes-ingress-controller"
LATEST_PRERELEASE=$(curl -s https://api.github.com/repos/${BASE}/releases | \
    jq -r '.[] | select(.tag_name | test("^2.[0-9]+.[0-9]+")) | .name' | head -1)

if [ "$LATEST_PRERELEASE" = "" ]; then
    echo "Error: could not find latest release for ${BASE}!${LATEST_PRERELEASE}"
    exit 1
fi

echo "INFO: the latest release of ${BASE} v2.x was determined to be ${LATEST_PRERELEASE}"

# ------------------------------------------------------------------------------
# Run Upgrade Tests
# ------------------------------------------------------------------------------

echo "INFO: running upgrade test to ${LATEST_PRERELEASE}"

RELEASE_NAME="chart-test-v2-upgrade" TEST_ENV_NAME=${TEST_ENV_NAME} TAG=${LATEST_PRERELEASE} ./scripts/test-upgrade.sh
