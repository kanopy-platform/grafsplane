GO_MODULE := $(shell git config --get remote.origin.url | grep -o 'github\.com[:/][^.]*' | tr ':' '/')
GIT_COMMIT := $(shell git rev-parse HEAD)
PACKAGE_NAME := grafsplane
REGISTRY_NAME ?= registry.example.com
TLS_VERIFY ?= false
CONTAINER_RUNTIME ?= podman
CONTEXT ?= kind-kind

RUN ?= .*
PKG ?= ./...


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

.PHONY: help
help:
