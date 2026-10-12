SHELL := /usr/bin/env bash
# Homebrew isn't on PATH in a bare shell (fresh install, non-login bash) and
# each recipe line is its own shell — prepend the brew prefixes for every
# target so `brew`, `mise`, etc. resolve without shellenv having run.
export PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)
SCRIPTS_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
DOTFILES_DIR := $(abspath $(SCRIPTS_DIR)/..)
SETUP := $(SCRIPTS_DIR)/setup
PACKAGES := agents claude ghostty git herdr launchagents mise nvim scripts shell starship tmux zsh
# Linux subset: launchagents is launchd. ghostty stays — it runs on Linux
# too, and an unused ~/.config/ghostty symlink costs nothing.
LINUX_PACKAGES := agents claude ghostty git herdr mise nvim scripts shell starship tmux zsh
REQUIRED_CMDS := stow brew git nvim mise tmux fzf starship
# linux-pkgs puts mise and herdr (and ai-clis claude) in ~/.local/bin mid-run,
# and make captured PATH before they existed — prepend it for every recipe. Linux
# only: on macOS it would put ~/.local/bin ahead of Homebrew for the
# existing targets.
ifneq ($(shell uname -s),Darwin)
export PATH := $(HOME)/.local/bin:$(PATH)
# No install.sh here, but each step's emit_result journals when this is set:
# a template built over ssh keeps a record of what ran and why it failed.
export INSTALL_RESULT_FILE := $(HOME)/.local/state/dotfiles/results.jsonl
# The target that installs this platform's base packages — what a missing-tool
# hint should point at.
PKGS_TARGET := linux-pkgs
else
PKGS_TARGET := brew
endif
# Every chain here is order-dependent (stow before stow is installed, mise
# before mise exists); -j would break them.
.NOTPARALLEL:

.PHONY: all install help brew brew-strict brew-pick-optional runtimes ssh defaults iterm agents ai-clis herdr status check lint test linux linux-pkgs stow-linux linux-shell

all: install

install:
	@bash $(SCRIPTS_DIR)/install.sh

help:
	@echo "Provisioning:"
	@echo "  make all        alias for 'make install'"
	@echo "  make install    pretty orchestrator with spinners + summary; falls back to"
	@echo "                  the plain make chain when VERBOSE=1 or stdout isn't a TTY"
	@echo "  make brew       full brew step: strict bundle + Brewfile.optional picker"
	@echo "  make runtimes   run 'mise install' for ~/.tool-versions (node, go, python, ruby)"
	@echo "  make ssh        generate ed25519 SSH key + ssh config (idempotent)"
	@echo "  make defaults   apply all macOS 'defaults write' settings"
	@echo "  make iterm      install iTerm2 shell integration"
	@echo "  make agents     load all repo LaunchAgents (keyremap, weekly drift check)"
	@echo "  make ai-clis    install claude (native) + kimi CLIs; verify mise-managed codex"
	@echo "  make herdr      install herdr's per-agent state integrations; keep"
	@echo "                  ~/.config/herdr a real dir so stow can't fold runtime state in"
	@echo ""
	@echo "Linux (headless agent VMs — no Homebrew, no macOS steps):"
	@echo "  make linux      full Linux chain: linux-pkgs + stow-linux + linux-shell +"
	@echo "                  runtimes + ai-clis + herdr"
	@echo "  make stow-linux stow only the packages that apply off macOS"
	@echo "  make linux-pkgs apt base + mise-managed CLIs + zsh plugins (Brewfile equivalent);"
	@echo "                  clipboard tools + Nerd Font when a desktop session is detected"
	@echo "  make linux-shell make zsh the login shell (after stow, so it has a .zshrc)"
	@echo ""
	@echo "Maintenance (status + check are macOS only — on Linux, 'make linux' re-provisions):"
	@echo "  make status     what the install chain ran / failed / never started, verified"
	@echo "                  against the live machine, with resume commands"
	@echo "                  (status.sh --check: probes only, exit 1 on drift — used by"
	@echo "                  the weekly com.vladsuciu.dotfiles-drift LaunchAgent)"
	@echo "  make check      audit symlinks, required commands, brew packages, git identity,"
	@echo "                  cask trust, CVE scan"
	@echo "  make lint       shellcheck setup scripts, install.sh, bootstrap.sh, macoss"
	@echo "  make test       probe + defaults --verify tests against fake \$$HOMEs"

brew: brew-strict brew-pick-optional

brew-strict:
	@command -v brew >/dev/null 2>&1 || /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	brew bundle --file=$(SCRIPTS_DIR)/Brewfile

brew-pick-optional:
	@bash $(SETUP)/pick-optional.sh

# mise finds ~/.tool-versions by walking up from the cwd, not as a global file;
# from a checkout outside $HOME it would install nothing and report success.
runtimes:
	@command -v mise >/dev/null 2>&1 || { echo "mise not found — run 'make $(PKGS_TARGET)' first" >&2; exit 1; }
	cd $$HOME && mise install

ssh:
	bash $(SETUP)/ssh.sh

defaults:
	bash $(SETUP)/defaults.sh

iterm:
	bash $(SETUP)/iterm.sh

agents:
	bash $(SETUP)/agents.sh

ai-clis:
	bash $(SETUP)/ai-clis.sh

herdr:
	bash $(SETUP)/herdr.sh

# ── Linux ───────────────────────────────────────────────────────────────────
# Parallel chain to the macOS one, not a step inside it: install.sh and
# status.sh stay macOS-only. Skipped here: brew (no Homebrew by design),
# defaults + iterm + agents (macOS/launchd), ssh (keys are per-machine and
# must never be generated into a VM template that gets cloned).
# Order matters: linux-pkgs installs stow; stow-linux links the .zshrc that
# linux-shell's chsh needs and the ~/.tool-versions runtimes reads.
linux: linux-pkgs stow-linux linux-shell runtimes ai-clis herdr
	@echo ""
	@echo "  ✓ Linux provisioning complete."
	@echo "    Shell plugins: ~/.local/share/zsh/plugins"
	@echo "    Not a VM template? 'make ssh' next — git signs every commit with that key."

stow-linux:
	@command -v stow >/dev/null 2>&1 || { echo "stow not found — run 'make linux-pkgs' first" >&2; exit 1; }
	stow -R -t $$HOME -d $(DOTFILES_DIR) $(LINUX_PACKAGES)

linux-pkgs:
	bash $(SETUP)/linux-pkgs.sh

linux-shell:
	bash $(SETUP)/linux-shell.sh

status:
	@bash $(SETUP)/status.sh

# Audits install.sh's chain (brew, casks, launchd) — off macOS every section
# would be red for the wrong reason, so decline up front.
check:
	@[ "$$(uname -s)" = Darwin ] || { echo "make check is macOS only — on Linux, run 'make linux' to re-provision" >&2; exit 1; }
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
	@echo ""
	@echo "── Cask trust (signed + notarized) ───────────"
	@bash $(SETUP)/cask-audit.sh
	@echo ""
	@echo "── Vulnerability scan (grype) ────────────────"
	@if ! command -v grype >/dev/null 2>&1; then \
		echo "  ⚠ grype not installed (run 'make brew')"; \
	else \
		bash $(SETUP)/grype-check.sh; \
	fi

lint:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found — run 'make $(PKGS_TARGET)' first" >&2; exit 1; }
	shellcheck -x --source-path=SCRIPTDIR $(SETUP)/*.sh $(SCRIPTS_DIR)/test/*.sh $(SCRIPTS_DIR)/install.sh $(SCRIPTS_DIR)/.bin/macoss $(DOTFILES_DIR)/bootstrap.sh
	@echo "  ✓ shellcheck clean"

test:
	@bash $(SCRIPTS_DIR)/test/run-tests.sh
