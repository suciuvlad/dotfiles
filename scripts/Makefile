SHELL := /usr/bin/env bash
SCRIPTS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
SETUP := $(SCRIPTS_DIR)/setup

.PHONY: all help brew node ssh defaults iterm

all: brew node ssh defaults iterm
	@echo ""
	@echo "All steps complete. Re-run a single step any time, e.g.:"
	@echo "    make defaults"

help:
	@echo "Targets:"
	@echo "  make all        run everything (brew → node → ssh → defaults → iterm)"
	@echo "  make brew       install Homebrew if needed, then 'brew bundle' (idempotent)"
	@echo "  make node       set node@lts as the global mise default"
	@echo "  make ssh        generate ed25519 SSH key + ssh config (idempotent)"
	@echo "  make defaults   apply all macOS 'defaults write' settings"
	@echo "  make iterm      install iTerm2 shell integration"

brew:
	@command -v brew >/dev/null 2>&1 || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew bundle --file=$(SCRIPTS_DIR)/Brewfile

node:
	@command -v mise >/dev/null 2>&1 || { echo "mise not found — run 'make brew' first" >&2; exit 1; }
	mise install
	mise use --global node@lts

ssh:
	bash $(SETUP)/ssh.sh

defaults:
	bash $(SETUP)/defaults.sh

iterm:
	bash $(SETUP)/iterm.sh
