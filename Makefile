# Some things this makefile could make use of:
#
# - test coverage target(s)
# - profiler target(s)
#

BIN             = rye
OUTPUT_DIR      = build
TMP_DIR        := .tmp
RELEASE_VER    := $(shell git rev-parse --short HEAD)
NAME            = default
COVERMODE       = atomic

TEST_PACKAGES      := $(shell go list ./... | grep -v vendor | grep -v fakes)

.PHONY: help
.DEFAULT_GOAL := help

all: test build docker ## Test, build and docker image build

setup: installtools ## Install and setup tools and local DB

# Under the hood, `go test -tags ...` also runs the "default" (unit) test case
# in addition to the specified tags
test: test/integration ## Perform both unit and integration tests

testv: testv/integration ## Perform both unit and integration tests (with verbose flags)

test/unit: ## Perform unit tests
	go test -cover $(TEST_PACKAGES)

testv/unit: ## Perform unit tests (with verbose flag)
	go test -v -cover $(TEST_PACKAGES)

test/integration: ## Perform integration tests
	go test -cover -tags integration $(TEST_PACKAGES)

testv/integration: ## Perform integration tests
	go test -v -cover -tags integration $(TEST_PACKAGES)

test/race: ## Perform unit tests and enable the race detector
	go test -race -cover $(TEST_PACKAGES)

test/cover: ## Run all tests + open coverage report for all packages
	echo 'mode: $(COVERMODE)' > .coverage
	for PKG in $(TEST_PACKAGES); do \
		go test -coverprofile=.coverage.tmp -tags "integration" $$PKG; \
		grep -v -E '^mode:' .coverage.tmp >> .coverage; \
	done
	go tool cover -html=.coverage
	$(RM) .coverage .coverage.tmp

installtools: ## Install development related tools
	go get github.com/kardianos/govendor
	go get github.com/maxbrunsfeld/counterfeiter

generate: ## Run generate for non-vendor packages only
	go list ./... | xargs go generate

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_\/-]+:.*?## / {printf "\033[34m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | \
		sort | \
		grep -v '#'