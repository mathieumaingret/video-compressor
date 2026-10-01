.DEFAULT_GOAL := help
SHELL := /bin/bash

COMPOSE ?= docker compose --project-directory . -f docker/compose/docker-compose.yml
# Recipes are silent so the scripts' output stays readable; "make Q= <target>" echoes them.
Q ?= @

SRC       ?= ./source
DEST      ?= ./dist
LOGS      ?= ./logs
CODEC     ?= libx265
CRF       ?=
PRESET    ?= medium
RECURSIVE ?= false
MOVFLAGS  ?= use_metadata_tags+faststart

ifeq ($(filter $(RECURSIVE),true false),)
$(error RECURSIVE must be true or false, got "$(RECURSIVE)")
endif

expand_home = $(patsubst ~%,$(HOME)%,$(1))
# Absolute, symlink-free paths: they are mounted in the container and written to the logs.
SRC_DIR  = $(shell cd "$(call expand_home,$(SRC))" 2>/dev/null && pwd -P)
DEST_DIR = $(shell mkdir -p "$(call expand_home,$(DEST))" && cd "$(call expand_home,$(DEST))" && pwd -P)
LOG_DIR  = $(shell mkdir -p "$(call expand_home,$(LOGS))" && cd "$(call expand_home,$(LOGS))" && pwd -P)

RUN = SRC_DIR="$(SRC_DIR)" DEST_DIR="$(DEST_DIR)" LOG_DIR="$(LOG_DIR)" \
	HOST_UID="$$(id -u)" HOST_GID="$$(id -g)" \
	CODEC="$(CODEC)" CRF="$(CRF)" PRESET="$(PRESET)" MOVFLAGS="$(MOVFLAGS)" RECURSIVE="$(RECURSIVE)" \
	DOCKER_CLI_HINTS=false $(COMPOSE) --progress quiet run --rm compressor

# Host folders are both the working roots and the paths written to the logs.
RUN_NATIVE = SRC_ROOT="$(SRC_DIR)" DEST_ROOT="$(DEST_DIR)" LOG_ROOT="$(LOG_DIR)" \
	SRC_HOST="$(SRC_DIR)" DEST_HOST="$(DEST_DIR)" LOG_HOST="$(LOG_DIR)" \
	CODEC="$(CODEC)" CRF="$(CRF)" PRESET="$(PRESET)" MOVFLAGS="$(MOVFLAGS)" RECURSIVE="$(RECURSIVE)" \
	./bin/compress-videos

.PHONY: help build compress-docker compress-native check shell purge require-src require-ffmpeg

help: ## Show this help
	@echo 'Usage: make <target> [SRC=...] [DEST=...] [LOGS=...] [CODEC=...] [CRF=...] [PRESET=...] [RECURSIVE=true]'
	@echo
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{ printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 }'
	@echo
	@echo 'Variables:'
	@echo '  SRC       Source folder scanned for .mp4 files (default: ./source)'
	@echo '  DEST      Destination folder (default: ./dist)'
	@echo '  LOGS      CSV log folder (default: ./logs)'
	@echo '  CODEC     libx265 (default) or libx264'
	@echo '  CRF       Quality, lower is better (default: 28 for x265, 23 for x264)'
	@echo '  PRESET    Encoder speed/size trade-off (default: medium)'
	@echo '  RECURSIVE true to also scan the subfolders of SRC (default: false)'
	@echo
	@echo 'Example: make compress-docker SRC=~/Pictures/DCIM DEST=~/Pictures/DCIM-compressed'

build: ## Build the ffmpeg image
	$(Q)$(COMPOSE) build

compress-docker: require-src ## Compress every video of SRC missing from DEST, with the Docker ffmpeg
	$(Q)$(RUN) compress-videos

compress-native: require-src require-ffmpeg ## Same as compress-docker with the host ffmpeg (~2x faster on macOS)
	$(Q)$(RUN_NATIVE)

check: require-src ## Compare metadata and mtime between SRC and DEST videos
	$(Q)$(RUN) check-metadata

shell: require-src ## Open a shell in the container, SRC and DEST mounted
	$(Q)$(RUN) bash

purge: ## Empty the project's source/, dist/ and logs/ (asks for confirmation, CONFIRM=yes to skip)
	$(Q)CONFIRM="$(CONFIRM)" ./bin/purge

require-src:
	@test -n "$(SRC_DIR)" || { echo "Source folder not found: $(SRC)" >&2; exit 1; }

require-ffmpeg:
	@command -v ffmpeg >/dev/null && command -v ffprobe >/dev/null || \
		{ echo "ffmpeg and ffprobe must be installed on the host (e.g. brew install ffmpeg)" >&2; exit 1; }
