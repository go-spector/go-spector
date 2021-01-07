PYTHON ?= python3
PLANTUML ?= plantuml
DIAGRAMS_DIR ?= docs/diagrams

CMD_SOURCE_FILES := $(shell find cmd -type f -name '*.go')
SOURCE_FILES := $(CMD_SOURCE_FILES)
DIAGRAMS_SRC_FILES := $(wildcard $(DIAGRAMS_DIR)/*.puml)
DIAGRAMS_SVG_FILES := $(patsubst %.puml,%.svg,$(DIAGRAMS_SRC_FILES))
DIAGRAMS_PNG_FILES := $(patsubst %.puml,%.png,$(DIAGRAMS_SRC_FILES))

GIT_SHA = sha-$(shell git log -n 1 --format="%h")
GIT_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
GIT_REV = $(shell git log -n 1 --format="%H")
DATE = $(shell date -u +"%Y-%m-%dT%TZ")

REPO := go-spector/go-spector
USERNAME = $(shell git config user.name)
EMAIL = $(shell git config user.email)
OCI_TITLE = go-spector
OCI_DESCRIPTION = Generate router, client and server code from API specifications
OCI_URL = https://github.com/$(REPO)
OCI_SOURCE = https://github.com/$(REPO)
OCI_VERSION = $(GIT_BRANCH)
OCI_CREATED = $(DATE)
OCI_REVISION = $(GIT_REV)
OCI_LICENSES = MIT
OCI_AUTHORS = Damiano Petrungaro, William Artero <william@artero.dev>
OCI_DOCUMENTATION = https://github.com/$(REPO)

.DEFAULT_GOAL := build

.PHONY: test
test:
	go test -race -v ./...

.PHONY: coverage
coverage: coverage.out
	@go tool cover -func=$<

.PHONY: coverage-html
coverage-html: coverage.html

%.html: %.out
	go tool cover -html=$< -o $@

%.out: $(SOURCE_FILES)
	@go test -race -cover -coverprofile=$@ -v ./...

.PHONY: build
build: go-spector

# golang targets
go-spector: $(SOURCE_FILES) vendor
	go build -mod=vendor -race -o ./ ./...

vendor: go.sum

go.sum: go.mod
	go mod vendor

.PHONY: run
run: vendor
	go run cmd/go-spector/main.go

# docker targets
.PHONY: image
image: Dockerfile $(SOURCE_FILES)
	@docker build \
		--label org.opencontainers.image.title=$(OCI_TITLE) \
		--label org.opencontainers.image.description="$(OCI_DESCRIPTION)" \
		--label org.opencontainers.image.url=$(OCI_URL) \
		--label org.opencontainers.image.source=$(OCI_SOURCE) \
		--label org.opencontainers.image.version=$(OCI_VERSION) \
		--label org.opencontainers.image.created=$(OCI_CREATED) \
		--label org.opencontainers.image.revision=$(OCI_REVISION) \
		--label org.opencontainers.image.licenses=$(OCI_LICENSES) \
		--label org.opencontainers.image.authors="$(OCI_AUTHORS)" \
		--label org.opencontainers.image.documentation=$(OCI_DOCUMENTATION) \
		--label org.opencontainers.image.vendor="$(OCI_VENDOR)" \
		--cache-from $(REPO):single-$(GIT_SHA) \
		--cache-from $(REPO):single-$(GIT_BRANCH) \
		--cache-from $(REPO):single-master \
		--cache-from $(REPO):single-latest \
  	--tag $(REPO):single-$(GIT_SHA) \
		--tag $(REPO):single-$(GIT_BRANCH) \
		--tag $(REPO):single-latest \
		.

.PHONY: image-buildx
image-buildx: Dockerfile $(SOURCE_FILES)
ifneq ($(shell git status --porcelain | wc -l | xargs), 0)
	@$(warning HEAD is not clean, aborting image build)
	@false
endif
	@docker buildx inspect --builder multi || docker buildx create --name multi --use
	@docker buildx build --builder multi \
  --platform linux/amd64,linux/arm/v7,linux/arm64 \
  --cache-to type=inline \
  --label org.opencontainers.image.title=$(OCI_TITLE) \
  --label org.opencontainers.image.description="$(OCI_DESCRIPTION)" \
  --label org.opencontainers.image.url=$(OCI_URL) \
  --label org.opencontainers.image.source=$(OCI_SOURCE) \
  --label org.opencontainers.image.version=$(OCI_VERSION) \
  --label org.opencontainers.image.created=$(OCI_CREATED) \
  --label org.opencontainers.image.revision=$(OCI_REVISION) \
  --label org.opencontainers.image.licenses=$(OCI_LICENSES) \
	--label org.opencontainers.image.authors="$(OCI_AUTHORS)" \
	--label org.opencontainers.image.documentation=$(OCI_DOCUMENTATION) \
	--label org.opencontainers.image.vendor="$(OCI_VENDOR)" \
  --cache-from $(REPO):$(GIT_SHA) \
  --cache-from $(REPO):$(GIT_BRANCH) \
	--cache-from $(REPO):master \
	--cache-from $(REPO):latest \
  --tag $(REPO):$(GIT_SHA) \
  --tag $(REPO):$(GIT_BRANCH) \
  --tag $(REPO):latest \
  --file ./Dockerfile .

# diagrams targets
.PHONY: diagrams
diagrams: $(DIAGRAMS_SVG_FILES) $(DIAGRAMS_PNG_FILES)

# docs targets
.PHONY: docs-sync
docs-sync: Pipfile.lock

. PHONY: docs-build
docs-build: docs-sync
	$(PYTHON) -m pipenv run mkdocs build

. PHONY: docs-serve
docs-serve: docs-sync
	$(PYTHON) -m pipenv run mkdocs serve

# rules
%.html: %.out
	go tool cover -html=$< -o $@

%.out: $(SOURCE_FILES)
	@go test -race -cover -coverprofile=$@ -v ./...

$(DIAGRAMS_DIR)/%.svg: $(DIAGRAMS_DIR)/%.puml
	$(info generating $@ from $<...)
	@$(PLANTUML) -tsvg $<

$(DIAGRAMS_DIR)/%.png: $(DIAGRAMS_DIR)/%.puml
	$(info generating $@ from $<...)
	@$(PLANTUML) -tpng $<

Pipfile.lock: Pipfile
