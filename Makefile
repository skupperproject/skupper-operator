VERSION := v1.4.0-rc2
REPLACES_VERSION := v1.3.0
SKIP_VERSIONS := 
BUNDLE_IMG ?= quay.io/skupper/skupper-operator-bundle:$(VERSION)
INDEX_IMG ?= quay.io/skupper/skupper-operator-index:$(VERSION)
OPM_URL := https://github.com/operator-framework/operator-registry/releases/latest/download/linux-amd64-opm
OPM := $(or $(shell which opm 2> /dev/null),./opm)
CONTAINER_TOOL := podman
CATALOG_YAML := skupper-operator-index/skupper-operator/catalog.yaml

all: index-build

.PHONY: verify-dup
verify-dup:
	@echo Validating catalog entries
	@export CATALOG_YAML="$(CATALOG_YAML)"; \
		export VERSION="$(VERSION)"; \
		./scripts/index_del_entry.sh

.PHONY: bundle-build ## Build the bundle image.
bundle-build: verify-dup test
	@echo Building bundle image
	$(CONTAINER_TOOL) build -f bundle.Dockerfile -t $(BUNDLE_IMG) .
	@echo Pushing $(BUNDLE_IMG)
	$(CONTAINER_TOOL) push $(BUNDLE_IMG)

.PHONY: opm-download
opm-download:
	@echo Checking if $(OPM) is available
ifeq (,$(wildcard $(OPM)))
	wget --quiet $(OPM_URL) -O ./opm && chmod +x ./opm
endif

#index-build: bundle-build opm-download
.PHONY: index-build ## Build the index image.
index-build: 
	$(info Using OPM Tool: $(OPM))
	@echo Adding new entry to catalog.yaml
	@export CATALOG_YAML="$(CATALOG_YAML)"; \
		export VERSION="$(VERSION)"; \
		export REP_VERSION="$(REPLACES_VERSION)"; \
		export SKIP_VERSIONS="$(SKIP_VERSIONS)"; \
		./scripts/index_add_entry.sh
	@echo Adding bundle to the catalog
	$(OPM) render $(BUNDLE_IMG) --output yaml >> $(CATALOG_YAML)
	$(OPM) validate skupper-operator-index/
	@echo Building index image
	$(CONTAINER_TOOL) build -f skupper-operator-index.Dockerfile -t $(INDEX_IMG) .
	@echo Pushing $(INDEX_IMG)
	$(CONTAINER_TOOL) push $(INDEX_IMG)

.PHONY: test
test:
	@rm -rf ./tmp || true
	mkdir ./tmp
	cp -r bundle/manifests/$(subst v,,$(VERSION)) ./tmp/manifests
	cp -r bundle/metadata ./tmp
	operator-sdk bundle validate ./tmp
