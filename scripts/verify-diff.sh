#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

DIR="${1}"

if git diff --quiet "${DIR}"
then
  echo "${DIR} up to date."
else
  echo "${DIR} appears to be out of date (make sure you've run 'make manifests' and 'make generate')"
  echo "Diff output:"
  git --no-pager diff "${DIR}"
  exit 1
fi
