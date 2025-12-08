# Simple Makefile to build the kernel via Docker/Podman and export to ./output

CONTAINER_RUNTIME := $(shell command -v docker 2>/dev/null || command -v podman 2>/dev/null)

ifeq ($(CONTAINER_RUNTIME),)
$(error Neither docker nor podman found in PATH. Please install one of them.)
endif

OUTPUT_DIR ?= output

.PHONY: all build

all: build

build:
	@echo "Using container runtime: $(CONTAINER_RUNTIME)"
	@echo "Building image and exporting artifacts to ./$(OUTPUT_DIR)"
	$(CONTAINER_RUNTIME) build --output $(OUTPUT_DIR) .
