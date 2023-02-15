.PHONY: lint
lint: ./scripts/*
	@for script in $^ ; do \
		shellcheck $${script} ; \
	done


KONG_CHART_GO_TEST_MODULE=charts/kong/tests
.PHONY: test
test:
	cd $(KONG_CHART_GO_TEST_MODULE) && \
	go test

.PHONY: generate
generate: generate.golden

.PHONY: generate.golden
generate.golden:
	cd $(KONG_CHART_GO_TEST_MODULE) && \
	rm testdata/golden/* && \
	go test -update-golden
