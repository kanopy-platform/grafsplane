GO_MODULE := $(shell git config --get remote.origin.url | grep -o 'github\.com[:/][^.]*' | tr ':' '/')
GIT_COMMIT := $(shell git rev-parse HEAD)
PACKAGE_NAME := grafsplane
REGISTRY_NAME ?= registry.example.com
TLS_VERIFY ?= false
CONTAINER_RUNTIME ?= podman
CONTEXT ?= kind-kind

RUN ?= .*
PKG ?= ./...

CROSSPLANE_VERSION ?= v1.20.13
OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH := $(shell uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')
BIN_DIR := $(CURDIR)/bin
CROSSPLANE := $(BIN_DIR)/crossplane-$(CROSSPLANE_VERSION)

EXAMPLES_DIR := examples/resources
EXAMPLES := dashboard folder datasource
RENDER_DIR := _output/render

# crossplane render runs functions in containers; on macOS podman runs in a VM
# so point the docker client at the podman machine socket.
ifeq ($(CONTAINER_RUNTIME)-$(OS),podman-darwin)
RENDER_ENV = DOCKER_HOST=unix://$$(podman machine inspect --format '{{.ConnectionInfo.PodmanSocket.Path}}')
endif


.PHONY: lint-pipeline
lint-pipeline:
	black .drone.star
	flake8 .drone.star


.PHONY: test
test: tidy ## Run tests in local environment
	golangci-lint run --timeout=5m $(PKG)
	go test -cover -short -run=$(RUN) $(PKG)

.PHONY:
tidy:
	go mod tidy
	go mod verify


.PHONY: docker-test
docker-test: ## Run tests using local development docker image
	@docker run -v $(pwd):/go/src/app/ --workdir=/go/src/app golang:1.20  go test -cover --coverprofile=coverage ./...

.PHONY: docker-snyk
docker-snyk: ## Run local snyk scan, SNYK_TOKEN environment variable must be set
	@docker run --rm -e SNYK_TOKEN -w /go/src/$(GO_MODULE) -v $(shell pwd):/go/src/$(GO_MODULE):delegated snyk/snyk:golang

.PHONY: docker
docker:
	@docker build --build-arg TAG=${PACKAGE_NAME} -t $(PACKAGE_NAME):latest .

.PHONY: docker-run
docker-run: docker ## Build and run the application in a local docker container
	@docker run -p ${DEFAULT_APP_PORT}:${DEFAULT_APP_PORT} $(CMD_NAME):latest


.PHONY: local
local:
	${CONTAINER_RUNTIME} build --build-arg TAG=${PACKAGE_NAME} -t ${REGISTRY_NAME}/$(PACKAGE_NAME):latest .
	${CONTAINER_RUNTIME} push ${REGISTRY_NAME}/$(PACKAGE_NAME):latest --tls-verify=${TLS_VERIFY}
	kubectl apply --context=${CONTEXT} -n crossplane-system -f examples/k8s/

$(CROSSPLANE):
	mkdir -p $(BIN_DIR)
	curl -fsSLo $@.tmp https://releases.crossplane.io/stable/$(CROSSPLANE_VERSION)/bin/$(OS)_$(ARCH)/crank
	chmod +x $@.tmp
	mv $@.tmp $@

.PHONY: install-crossplane
install-crossplane: $(CROSSPLANE) ## Install the crossplane CLI into ./bin

.PHONY: podman-machine
podman-machine:
ifeq ($(CONTAINER_RUNTIME)-$(OS),podman-darwin)
	@if [ "$$(podman machine inspect --format '{{.State}}' 2>/dev/null)" != "running" ]; then podman machine start; fi
endif

.PHONY: render
render: $(CROSSPLANE) podman-machine ## Render examples/resources through config/composition.yaml into _output/render
	@rm -rf $(RENDER_DIR)
	@mkdir -p $(RENDER_DIR)/inputs $(RENDER_DIR)/output
	@set -e; \
	pkg=$$(yq '.spec.package' $(EXAMPLES_DIR)/function.yaml); \
	ver=$$(PKG=$$pkg yq '.spec.dependsOn[] | select(.function == strenv(PKG)) | .version' config/crossplane.yaml); \
	if [ -z "$$ver" ]; then echo "no dependsOn version for $$pkg in config/crossplane.yaml"; exit 1; fi; \
	VER=$$ver yq '.spec.package += ":" + strenv(VER)' $(EXAMPLES_DIR)/function.yaml > $(RENDER_DIR)/inputs/function.yaml
	@set -e; for ex in $(EXAMPLES); do \
		kind=$$(yq '.kind' $(EXAMPLES_DIR)/$$ex.yaml); \
		KIND=$$kind yq 'select(.kind == "Composition" and .spec.compositeTypeRef.kind == strenv(KIND))' config/composition.yaml > $(RENDER_DIR)/inputs/composition-$$ex.yaml; \
		echo "rendering $$ex ($$kind)"; \
		$(RENDER_ENV) $(CROSSPLANE) render $(EXAMPLES_DIR)/$$ex.yaml $(RENDER_DIR)/inputs/composition-$$ex.yaml $(RENDER_DIR)/inputs/function.yaml > $(RENDER_DIR)/output/$$ex.yaml; \
	done

.PHONY: render-check
render-check: render ## Render examples and diff against examples/resources/expected
	diff -ru $(EXAMPLES_DIR)/expected $(RENDER_DIR)/output

.PHONY: render-update
render-update: render ## Render examples and overwrite examples/resources/expected
	cp $(RENDER_DIR)/output/*.yaml $(EXAMPLES_DIR)/expected/

.PHONY: help
help:
