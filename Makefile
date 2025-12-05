PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
TOOLS_VERSIONS_FILE = .tools_versions.yaml

MISE := $(shell which mise)
MISE_FILE := .mise.toml
MISE_DATA_DIR := $(PROJECT_DIR)/bin

.PHONY: mise
mise:
	@mise -V >/dev/null || (echo "mise - https://github.com/jdx/mise - not found. Please install it." && exit 1)

# NOTE: mise targets use -q to silence the output.
# Users can use MISE_VERBOSE=1 MISE_DEBUG=1 to get more verbose output.

.PHONY: mise-plugin-install
mise-plugin-install: mise
	@$(MISE) plugin install --yes -q $(DEP) $(URL)

.PHONY: mise-install
mise-install: mise
	@$(MISE) install -q $(DEP_VER)

KUBE_LINTER_VERSION = $(shell yq -ojson -r '.kube-linter' < $(TOOLS_VERSIONS_FILE))
KUBE_LINTER = $(PROJECT_DIR)/bin/installs/github-stackrox-kube-linter/$(KUBE_LINTER_VERSION)/kube-linter
.PHONY: kube-linter
kube-linter:
	MISE_DATA_DIR=$(MISE_DATA_DIR) $(MAKE) mise-install DEP_VER=github:stackrox/kube-linter@$(KUBE_LINTER_VERSION)

CHARTSNAP_VERSION = $(shell yq -ojson -r '.chartsnap' < $(TOOLS_VERSIONS_FILE))
.PHONY: chartsnap
chartsnap: download.helm
	HELM=$(HELM) CHARTSNAP_VERSION=$(CHARTSNAP_VERSION) ./scripts/install-chartsnap.sh

SHELLCHECK_VERSION = $(shell yq -ojson -r '.shellcheck' < $(TOOLS_VERSIONS_FILE))
SHELLCHECK = $(PROJECT_DIR)/bin/installs/github-koalaman-shellcheck/$(SHELLCHECK_VERSION)/shellcheck
.PHONY: download.shellcheck
download.shellcheck:
	MISE_DATA_DIR=$(MISE_DATA_DIR) $(MAKE) mise-install DEP_VER=github:koalaman/shellcheck@$(SHELLCHECK_VERSION)

ACTIONLINT_VERSION = $(shell yq -r '.actionlint' < $(TOOLS_VERSIONS_FILE))
ACTIONLINT = $(PROJECT_DIR)/bin/installs/github-rhysd-actionlint/$(ACTIONLINT_VERSION)/actionlint
.PHONY: download.actionlint
download.actionlint:
	MISE_DATA_DIR=$(MISE_DATA_DIR) $(MAKE) mise-install DEP_VER=github:rhysd/actionlint@$(ACTIONLINT_VERSION)

HELM_VERSION = $(shell yq -p toml -o yaml '.tools["http:helm"].version' < $(MISE_FILE))
HELM = helm
.PHONY: download.helm
download.helm:
	@$(MAKE) mise-install DEP_VER=http:helm

.PHONY: print.helm
print.helm: download.helm
	@echo "$(HELM)"

.PHONY: verify.diff
verify.diff:
	@$(PROJECT_DIR)/scripts/verify-diff.sh $(PROJECT_DIR)

.PHONY: tools
tools: kube-linter chartsnap download.shellcheck

.PHONY: lint
lint: tools lint.charts lint.shellcheck lint.actions

.PHONY: lint.charts
lint.charts:
	$(KUBE_LINTER) lint charts/

.PHONY: lint.shellcheck
lint.shellcheck: download.shellcheck
	$(SHELLCHECK) ./scripts/*
	$(SHELLCHECK) ./charts/gateway-operator/scripts/*

.PHONY: lint.actions
lint.actions: download.actionlint download.shellcheck
# TODO: add more files to be checked
	$(ACTIONLINT) -shellcheck $(SHELLCHECK) \
		./.github/workflows/*

.PHONY: test.golden
test.golden:
	@ \
		$(MAKE) _chartsnap CHART=kong && \
		$(MAKE) _chartsnap CHART=ingress && \
		$(MAKE) _chartsnap CHART=gateway-operator || \
	(echo "$$GOLDEN_TEST_FAILURE_MSG" && exit 1)

.PHONY: test.golden.update
test.golden.update: download.helm
	$(HELM) repo update kong
	@ $(MAKE) _chartsnap CHART=kong CHARTSNAP_ARGS="-u"
	@ $(MAKE) _chartsnap CHART=ingress CHARTSNAP_ARGS="-u"
	@ $(MAKE) _chartsnap CHART=gateway-operator CHARTSNAP_ARGS="-u"

# Defining multi-line strings to echo: https://stackoverflow.com/a/649462/7958339
define GOLDEN_TEST_FAILURE_MSG
>> Golden tests have failed.
>> Please run 'make test.golden.update' to update golden files and commit the changes if they're expected.
endef
export GOLDEN_TEST_FAILURE_MSG

.PHONY: _chartsnap
_chartsnap: _chartsnap.deps
	$(HELM) chartsnap \
		-c ./charts/$(CHART) \
		-f ./charts/$(CHART)/ci/ \
		$(CHARTSNAP_ARGS) \
		-- \
		--api-versions cert-manager.io/v1 \
		--api-versions gateway.networking.k8s.io/v1 \
		--api-versions gateway.networking.k8s.io/v1beta1 \
		--api-versions gateway.networking.k8s.io/v1alpha2 \
		--api-versions admissionregistration.k8s.io/v1/ValidatingAdmissionPolicy \
		--api-versions admissionregistration.k8s.io/v1/ValidatingAdmissionPolicyBinding

.PHONY: _chartsnap.deps
_chartsnap.deps: download.helm chartsnap
	@ if [ "$(CHART)" = "kong" ]; then \
		$(HELM) dependencies update charts/ingress; \
	fi
