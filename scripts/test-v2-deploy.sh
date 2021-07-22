#!/usr/bin/env bash

# ------------------------------------------------------------------------------
# test-v2-deploy.sh
#
# This script is temporary: in the timeframe between 1.x and 2.x KIC
# releases this script was made to validate that basic deployments of the
# V2 pre-release images functioned properly. once 2.0 releases fully
# this script will be removed because all tests thereafter will be
# running on that version and it's lineage.
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "${SCRIPT_DIR}/.."


TEST_ENV_NAME="${TEST_ENV_NAME:-kong-charts-tests}"

# ------------------------------------------------------------------------------
# Find and Test Latest V2 Tag
# ------------------------------------------------------------------------------

BASE="kong/kubernetes-ingress-controller"
TAG="$(curl -s https://api.github.com/repos/${BASE}/releases | jq -r '.[] | select(.tag_name | test("^2.[0-9]+.[0-9]+")) | .name' | head -1)"

echo "INFO: running tests for ${TAG}"
TEST_ENV_NAME=${TEST_ENV_NAME} RELEASE_NAME="chart-test-v2-deploy" TAG=${TAG} "${SCRIPT_DIR}/test-run.sh"
