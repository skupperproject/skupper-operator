VERSION ?= v1.3.0
PREV_VERSION ?= v1.1.1
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
	@cat $(CATALOG_YAML) | yq --arg version "$(VERSION)" -y 'del(. | select(.name == "skupper-operator." + $$version)) | del(.entries[]? | select(.name == "skupper-operator." + $$version))' \
		| sed -re '/^(--- null|\.\.\.)$$/d' > catalog.yaml.tmp && mv catalog.yaml.tmp $(CATALOG_YAML)

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

.PHONY: index-build ## Build the index image.
index-build: bundle-build opm-download
	$(info Using OPM Tool: $(OPM))
	@echo Adding new entry to catalog.yaml
	@cat $(CATALOG_YAML) | yq -y 'if .entries then .entries+=[{"name": "skupper-operator.$(VERSION)", "replaces": "skupper-operator.$(PREV_VERSION)"}] else . end' > $(CATALOG_YAML).new
	@mv $(CATALOG_YAML).new $(CATALOG_YAML)
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
