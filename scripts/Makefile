SHELL := /usr/bin/env bash
SCRIPTS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
DOTFILES_DIR := $(abspath $(SCRIPTS_DIR)/..)
SETUP := $(SCRIPTS_DIR)/setup
PACKAGES := claude ghostty git mise nvim scripts shell starship tmux zsh
REQUIRED_CMDS := stow brew git nvim mise tmux fzf starship

.PHONY: all help brew node ssh defaults iterm check lint

all: brew node ssh defaults iterm
	@echo ""
	@echo "All steps complete. Re-run a single step any time, e.g.:"
	@echo "    make defaults"

help:
	@echo "Provisioning:"
	@echo "  make all        run brew → node → ssh → defaults → iterm"
	@echo "  make brew       install Homebrew if needed, then 'brew bundle' (idempotent)"
	@echo "  make node       run 'mise install' for ~/.tool-versions, set node@lts global"
	@echo "  make ssh        generate ed25519 SSH key + ssh config (idempotent)"
	@echo "  make defaults   apply all macOS 'defaults write' settings"
	@echo "  make iterm      install iTerm2 shell integration"
	@echo ""
	@echo "Maintenance:"
	@echo "  make check      audit symlinks, required commands, brew packages, git identity"
	@echo "  make lint       shellcheck setup scripts and macoss"

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

check:
	@echo "── Symlinks ──────────────────────────────────"
	@broken=$$(find $$HOME/.config $$HOME -maxdepth 4 -type l ! -exec test -e {} \; -print 2>/dev/null | grep dotfiles || true); \
	if [ -z "$$broken" ]; then \
		echo "  ✓ no broken symlinks pointing into dotfiles"; \
	else \
		echo "  ✗ broken symlinks found:"; echo "$$broken" | sed 's/^/    /'; \
	fi
	@echo ""
	@echo "── Required commands ─────────────────────────"
	@missing=0; \
	for cmd in $(REQUIRED_CMDS); do \
		if command -v $$cmd >/dev/null 2>&1; then \
			printf "  ✓ %s\n" $$cmd; \
		else \
			printf "  ✗ %s (run 'make brew')\n" $$cmd; missing=1; \
		fi; \
	done
	@echo ""
	@echo "── Brewfile satisfied? ───────────────────────"
	@if brew bundle check --file=$(SCRIPTS_DIR)/Brewfile >/dev/null 2>&1; then \
		echo "  ✓ all packages installed"; \
	else \
		echo "  ✗ missing packages — run 'make brew'"; \
	fi
	@echo ""
	@echo "── Git identity ──────────────────────────────"
	@name=$$(git config --global user.name); email=$$(git config --global user.email); \
	[ -n "$$name" ]  && echo "  ✓ user.name:  $$name"  || echo "  ✗ user.name unset"
	@email=$$(git config --global user.email); \
	[ -n "$$email" ] && echo "  ✓ user.email: $$email" || echo "  ✗ user.email unset"
	@echo ""
	@echo "── Stow packages ─────────────────────────────"
	@for pkg in $(PACKAGES); do \
		if [ -d "$(DOTFILES_DIR)/$$pkg" ]; then \
			printf "  ✓ %s/\n" $$pkg; \
		else \
			printf "  ✗ %s/ MISSING\n" $$pkg; \
		fi; \
	done

lint:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found — run 'make brew'" >&2; exit 1; }
	shellcheck $(SETUP)/*.sh $(SCRIPTS_DIR)/.bin/macoss
	@echo "  ✓ shellcheck clean"
