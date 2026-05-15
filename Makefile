# Makefile for telegraf
# Provides common development tasks

PLATFORM ?= $(shell go env GOOS)
ARCH ?= $(shell go env GOARCH)
VERSION ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "unknown")
COMMIT ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
BUILD_DATE ?= $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

LDFLAGS := -ldflags "-X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.branch=$(BRANCH)"

BINARY := telegraf
BIN_DIR := bin

.PHONY: all build clean test lint fmt vet deps help

all: deps build

## build: Compile the binary for the current platform
build:
	@echo "Building $(BINARY) $(VERSION) for $(PLATFORM)/$(ARCH)..."
	@mkdir -p $(BIN_DIR)
	go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY) ./cmd/telegraf

## build-all: Compile binaries for all supported platforms
build-all:
	@echo "Building for all platforms..."
	@mkdir -p $(BIN_DIR)
	GOOS=linux   GOARCH=amd64  go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY)_linux_amd64   ./cmd/telegraf
	GOOS=linux   GOARCH=arm64  go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY)_linux_arm64   ./cmd/telegraf
	GOOS=darwin  GOARCH=amd64  go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY)_darwin_amd64  ./cmd/telegraf
	GOOS=darwin  GOARCH=arm64  go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY)_darwin_arm64  ./cmd/telegraf
	GOOS=windows GOARCH=amd64  go build $(LDFLAGS) -o $(BIN_DIR)/$(BINARY)_windows_amd64.exe ./cmd/telegraf

## test: Run unit tests
test:
	@echo "Running tests..."
	go test -v -race -timeout 120s ./...

## test-short: Run short unit tests only
test-short:
	@echo "Running short tests..."
	go test -short -timeout 30s ./...

## lint: Run golangci-lint
lint:
	@echo "Running linter..."
	golangci-lint run ./...

## fmt: Format Go source files
fmt:
	@echo "Formatting source files..."
	gofmt -s -w $$(find . -name '*.go' -not -path './vendor/*')

## vet: Run go vet
vet:
	@echo "Running go vet..."
	go vet ./...

## deps: Download and tidy dependencies
deps:
	@echo "Downloading dependencies..."
	go mod download
	go mod tidy

## clean: Remove build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BIN_DIR)

## check: Run fmt, vet, and lint
check: fmt vet lint

## help: Display this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^## ' Makefile | sed 's/## /  /'
