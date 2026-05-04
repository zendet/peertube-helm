.PHONY: docs bump

docs:
	helm-docs

# make bump VERSION=0.1.X
# make bump APP_VERSION=v8.0.X
# make bump VERSION=0.1.X APP_VERSION=v8.0.X
bump:
	@if [ -z "$(VERSION)$(APP_VERSION)" ]; then \
		echo "error: set VERSION and/or APP_VERSION (e.g. make bump VERSION=0.1.3)"; \
		exit 1; \
	fi
	@if [ -n "$(VERSION)" ]; then \
		sed -i -E 's/^version: .*/version: $(VERSION)/' Chart.yaml; \
		echo "Chart version -> $(VERSION)"; \
	fi
	@if [ -n "$(APP_VERSION)" ]; then \
		sed -i -E 's/^appVersion: .*/appVersion: "$(APP_VERSION)"/' Chart.yaml; \
		echo "App version   -> $(APP_VERSION)"; \
	fi
	@$(MAKE) --no-print-directory docs
