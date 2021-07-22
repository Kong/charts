.PHONY: lint
lint: ./scripts/*
	@for script in $^ ; do \
		shellcheck $${script} ; \
	done
