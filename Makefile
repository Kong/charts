PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
CHARTSNAP_VERSION ?= v0.3.1

.PHONY: _download_tool
_download_tool:
	(cd third_party && go mod tidy && \
		GOBIN=$(PROJECT_DIR)/bin go generate -tags=third_party ./$(TOOL).go )

.PHONY: tools
tools: kube-linter chartsnap

KUBE_LINTER = $(PROJECT_DIR)/bin/kube-linter
.PHONY: kube-linter
kube-linter:
	@$(MAKE) _download_tool TOOL=kube-linter

.PHONY: chartsnap
chartsnap:
	./scripts/install-chartsnap.sh

.PHONY: lint
lint: tools lint.charts.kong lint.shellcheck

.PHONY: lint.charts.kong
lint.charts.kong:
	$(KUBE_LINTER) lint charts/kong

lint.shellcheck:
	shellcheck ./scripts/*

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
	@ helm chartsnap -c ./charts/$(GOLDEN_TEST_CHART) -f $(GOLDEN_TEST_CHART_VALUES_DIR) $(CHARTSNAP_ARGS)
