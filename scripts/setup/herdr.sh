#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# herdr — terminal multiplexer for AI coding agents. The binary itself comes
# from the strict Brewfile; this step owns the two things brew can't do:
#
#   1. Agent integrations. Per-agent hooks that report real lifecycle state
#      (idle/working/blocked/done) to herdr's sidebar. Without them herdr can
#      only guess from screen output, and `resume_agents_on_restore` has no
#      session refs to resume from. They version independently of herdr and go
#      stale when an agent updates, so they need re-running, not just install.
#   2. Unfolding ~/.config/herdr. herdr writes session.json (which carries
#      agent conversation refs), logs and sockets next to the stowed
#      config.toml. If stow folded that directory into a symlink, all of it
#      lands inside the repo. Same hazard as ~/Library/LaunchAgents.

DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Only integrations for agents this repo provisions (see ai-clis.sh) plus
# cursor. herdr ships many more kinds; installing one for an absent agent just
# writes a hook that never fires.
INTEGRATIONS=(claude codex cursor kimi)

failed=()
installed=()

# ── 1. Keep ~/.config/herdr a real directory ────────────────────────────────
if [ -L "$HOME/.config/herdr" ]; then
  echo "→ ~/.config/herdr is a symlink (stow folded it) — unfolding"
  unlink "$HOME/.config/herdr"
fi
mkdir -p "$HOME/.config/herdr"

# Re-stow so config.toml is linked per-file into the real directory. Tolerated
# if stow is missing — 'make brew' installs it and this step re-runs cheaply.
if command -v stow >/dev/null 2>&1; then
  stow -R -t "$HOME" -d "$DOTFILES_DIR" herdr 2>/dev/null \
    || failed+=("stow herdr — re-stow failed, check for conflicting ~/.config/herdr/config.toml")
fi

# ── 2. Agent integrations ───────────────────────────────────────────────────
if ! command -v herdr >/dev/null 2>&1; then
  failed+=("herdr — not installed; run 'make brew'")
else
  # `integration status` prints one line per kind:
  #   claude: current (v7) (/path/to/hook)
  #   pi: not installed (/path/to/hook)
  # Re-install anything not already current. Installing is idempotent, but
  # skipping the current ones keeps the step quiet and fast.
  status_out=$(herdr integration status 2>/dev/null || true)

  for kind in "${INTEGRATIONS[@]}"; do
    case $'\n'"$status_out" in
      *$'\n'"$kind: current"*)
        echo "· $kind integration current"
        continue ;;
    esac
    echo "→ installing $kind integration"
    if herdr integration install "$kind" >/dev/null 2>&1; then
      installed+=("$kind")
    else
      failed+=("$kind — herdr integration install failed")
    fi
  done
fi

# ── Result ──────────────────────────────────────────────────────────────────
if [ ${#failed[@]} -gt 0 ]; then
  printf '✗ %s\n' "${failed[@]}" >&2
  emit_result "herdr" "warn" "${#failed[@]} issue(s)" "${failed[@]}"
  exit 1
fi

[ ${#installed[@]} -gt 0 ] && echo "✓ installed integrations: ${installed[*]}"
echo "✓ herdr ready — config linked, ${#INTEGRATIONS[@]} agent integrations current"
emit_result "herdr" "ok" "${#INTEGRATIONS[@]} integrations current"
