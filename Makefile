PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))

.PHONY: _download_tool
_download_tool:
	(cd third_party && go mod tidy && \
		GOBIN=$(PROJECT_DIR)/bin go generate -tags=third_party ./$(TOOL).go )

.PHONY: tools
tools: kube-linter

KUBE_LINTER = $(PROJECT_DIR)/bin/kube-linter
.PHONY: kube-linter
kube-linter:
	@$(MAKE) _download_tool TOOL=kube-linter

.PHONY: lint
lint: tools lint.charts.kong lint.shellcheck

.PHONY: lint.charts.kong
lint.charts.kong:
	$(KUBE_LINTER) lint charts/kong

lint.shellcheck:
	shellcheck ./scripts/*

KONG_CHART_GO_TEST_MODULE=charts/kong/tests
TEST_GOLDEN_TESTCASE_NAME=TestGolden
.PHONY: test
test:
	cd $(KONG_CHART_GO_TEST_MODULE) && \
	go test ./...

.PHONY: test.golden.update
test.golden.update:
	cd $(KONG_CHART_GO_TEST_MODULE) && \
	rm testdata/golden/* && \
	go test -run $(TEST_GOLDEN_TESTCASE_NAME) -update-golden
