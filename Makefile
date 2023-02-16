# Get the currently used golang install path (in GOPATH/bin, unless GOBIN is set)
ifeq (,$(shell go env GOBIN))
GOBIN=$(shell go env GOPATH)/bin
else
GOBIN=$(shell go env GOBIN)
endif

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
lint: ./scripts/*
	@for script in $^ ; do \
		shellcheck $${script} ; \
	done
	$(KUBE_LINTER) lint charts/kong
