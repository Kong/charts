PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
TOOLS_VERSIONS_FILE = .tools_versions.yaml

MISE := $(shell which mise)
.PHONY: mise
mise:
	@mise -V >/dev/null || (echo "mise - https://github.com/jdx/mise - not found. Please install it." && exit 1)

export MISE_DATA_DIR = $(PROJECT_DIR)/bin/

# NOTE: mise targets use -q to silence the output.
# Users can use MISE_VERBOSE=1 MISE_DEBUG=1 to get more verbose output.

.PHONY: mise-plugin-install
mise-plugin-install: mise
	@$(MISE) plugin install --yes -q $(DEP) $(URL)

.PHONY: mise-install
mise-install: mise
	@$(MISE) install -q $(DEP_VER)

KUBE_LINTER_VERSION = $(shell yq -ojson -r '.kube-linter' < $(TOOLS_VERSIONS_FILE))
KUBE_LINTER = $(PROJECT_DIR)/bin/installs/kube-linter/v$(KUBE_LINTER_VERSION)/bin/kube-linter
.PHONY: kube-linter
kube-linter: mise
	@$(MAKE) mise-plugin-install DEP=kube-linter
	@$(MAKE) mise-install DEP_VER=kube-linter@v$(KUBE_LINTER_VERSION)

CHARTSNAP_VERSION = $(shell yq -ojson -r '.chartsnap' < $(TOOLS_VERSIONS_FILE))
.PHONY: chartsnap
chartsnap:
	CHARTSNAP_VERSION=${CHARTSNAP_VERSION} ./scripts/install-chartsnap.sh

SHELLCHECK_VERSION = $(shell yq -ojson -r '.shellcheck' < $(TOOLS_VERSIONS_FILE))
SHELLCHECK = $(PROJECT_DIR)/bin/installs/shellcheck/$(SHELLCHECK_VERSION)/bin/shellcheck
.PHONY: shellcheck
shellcheck: mise
	@$(MAKE) mise-plugin-install DEP=shellcheck
	@$(MAKE) mise-install DEP_VER=shellcheck@$(SHELLCHECK_VERSION)

.PHONY: tools
tools: kube-linter chartsnap shellcheck

.PHONY: lint
lint: tools lint.charts.kong lint.shellcheck

.PHONY: lint.charts.kong
lint.charts.kong:
	$(KUBE_LINTER) lint charts/kong

.PHONY: lint.shellcheck
lint.shellcheck: shellcheck
	$(SHELLCHECK) ./scripts/*
	$(SHELLCHECK) ./charts/gateway-operator/scripts/*

.PHONY: test.golden
test.golden:
	@ $(MAKE) _chartsnap.kong && $(MAKE) _chartsnap.ingress || \
	(echo "$$GOLDEN_TEST_FAILURE_MSG" && exit 1)

.PHONY: test.golden.update
test.golden.update:
	@ $(MAKE) _chartsnap.kong CHARTSNAP_ARGS="-u"
	@ $(MAKE) _chartsnap.ingress CHARTSNAP_ARGS="-u"

# Defining multi-line strings to echo: https://stackoverflow.com/a/649462/7958339
define GOLDEN_TEST_FAILURE_MSG
>> Golden tests have failed.
>> Please run 'make test.golden.update' to update golden files and commit the changes if they're expected.
endef
export GOLDEN_TEST_FAILURE_MSG

.PHONY: _chartsnap.kong
_chartsnap.kong:
	@ $(MAKE) _chartsnap GOLDEN_TEST_CHART=kong GOLDEN_TEST_CHART_VALUES_DIR=./charts/kong/ci/ \
	CHARTSNAP_ARGS=$(CHARTSNAP_ARGS)

.PHONY: _chartsnap.ingress
_chartsnap.ingress:
	@ $(MAKE) _chartsnap GOLDEN_TEST_CHART=ingress GOLDEN_TEST_CHART_VALUES_DIR=./charts/ingress/ci/ \
	CHARTSNAP_ARGS=$(CHARTSNAP_ARGS)

.PHONY: _chartsnap
_chartsnap: chartsnap
	@ helm repo update kong
	@ helm dependencies update charts/ingress
	@ helm chartsnap -c ./charts/$(GOLDEN_TEST_CHART) -f $(GOLDEN_TEST_CHART_VALUES_DIR) $(CHARTSNAP_ARGS)
