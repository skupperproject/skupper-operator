VERSION := v2.0.0
BUNDLE_IMG ?= quay.io/skupper/skupper-operator-bundle:$(VERSION)
INDEX_IMG ?= quay.io/skupper/skupper-operator-index:$(VERSION)
OPM_URL := https://github.com/operator-framework/operator-registry/releases/latest/download/linux-amd64-opm
OPM := $(or $(shell which opm 2> /dev/null),./opm)
CONTAINER_TOOL := podman
CATALOG_YAML := skupper-operator-index/skupper-operator/catalog.yaml
PLATFORMS ?= linux/amd64,linux/arm64

all: index-build

.PHONY: bundle-build ## Build the bundle image.
bundle-build: validate-bundle
	@echo Building bundle image
	$ pushd ./bundle/$(subst v,,$(VERSION)) && \
	$(CONTAINER_TOOL) buildx build --no-cache --platform ${PLATFORMS} --manifest skupper-operator-bundle -t $(BUNDLE_IMG) -f bundle.Dockerfile .
	@echo Pushing $(BUNDLE_IMG)
	$(CONTAINER_TOOL) manifest push --all skupper-operator-bundle $(BUNDLE_IMG) && \
	cd ../../

.PHONY: opm-download
opm-download:
	@echo Checking if $(OPM) is available
ifeq (,$(wildcard $(OPM)))
	wget --quiet $(OPM_URL) -O ./opm && chmod +x ./opm
endif

.PHONY: index-build ## Build the index image.
index-build: bundle-build opm-download
	$(info Using OPM Tool: $(OPM))
	@echo Adding unique $(VERSION) entry to catalog.yaml
	@python ./scripts/index_update.py $(CATALOG_YAML)
	@echo Adding bundle to the catalog
	$(OPM) render $(BUNDLE_IMG) --output yaml >> $(CATALOG_YAML)
	$(OPM) validate skupper-operator-index/
	@echo Building index image
	$(CONTAINER_TOOL) buildx build --no-cache --platform ${PLATFORMS} --manifest skupper-operator-index -f skupper-operator-index.Dockerfile -t $(INDEX_IMG) .
	@echo Pushing $(INDEX_IMG)
	$(CONTAINER_TOOL) manifest push --all skupper-operator-index $(INDEX_IMG)

.PHONY: index-build2 ## Build the index image.
index-build2: bundle-build opm-download
	$(info Using OPM Tool: $(OPM))
	@echo Adding unique $(VERSION) entry to catalog.yaml
	@echo Adding bundle to the catalog
	$(OPM) render $(BUNDLE_IMG) --output yaml >> $(CATALOG_YAML)
	$(OPM) validate skupper-operator-index/
	@echo Building index image
	$(CONTAINER_TOOL) buildx build --no-cache --platform ${PLATFORMS} --manifest skupper-operator-index -f skupper-operator-index.Dockerfile -t $(INDEX_IMG) .
	@echo Pushing $(INDEX_IMG)
	$(CONTAINER_TOOL) manifest push --all skupper-operator-index $(INDEX_IMG)

.PHONY: validate-bundle
validate-bundle:
	operator-sdk bundle validate ./bundle/$(subst v,,$(VERSION))

.PHONY: validate-index
validate-index:
	$(OPM) validate skupper-operator-index/
