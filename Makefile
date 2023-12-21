PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

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
	@helm plugin list | grep chartsnap > /dev/null || \
	helm plugin install https://github.com/jlandowner/helm-chartsnap

.PHONY: lint
lint: tools lint.charts.kong lint.shellcheck

.PHONY: lint.charts.kong
lint.charts.kong:
	$(KUBE_LINTER) lint charts/kong

lint.shellcheck:
	shellcheck ./scripts/*

GOLDEN_TEST_CHART ?= kong
GOLDEN_TEST_CHART_VALUES_DIR ?= ./charts/kong/ci/
CHARTSNAP_COMMAND = helm chartsnap -c ./charts/$(GOLDEN_TEST_CHART) -f $(GOLDEN_TEST_CHART_VALUES_DIR)

.PHONY: test.golden
test.golden: chartsnap
	$(CHARTSNAP_COMMAND) || \
	(echo ">> Golden tests have failed.\n>> Please run 'make test.golden.update' to update golden files and commit the changes if they're expected." && \
	exit 1)

.PHONY: test.golden.update
test.golden.update: chartsnap
	$(CHARTSNAP_COMMAND) -u
