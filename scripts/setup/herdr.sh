#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# herdr — terminal multiplexer for AI coding agents. The binary itself comes
# from the strict Brewfile (linux-pkgs.sh on Linux); this step owns the two
# things a package manager can't do:
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
# cursor. herdr ships many more kinds, and refuses to install one whose agent
# config dir is missing — on a fresh box that is every CLI that has never run.
INTEGRATIONS=(claude codex cursor kimi)

# Where each agent keeps its config, and the binary that proves it's installed.
# A present binary with no config dir (installed, never launched) gets the dir
# created so the hook can land; no binary and no dir means skip, not fail.
agent_dir() {
  case "$1" in
    claude) echo "$HOME/.claude" ;;
    codex)  echo "$HOME/.codex" ;;
    cursor) echo "$HOME/.cursor" ;;
    kimi)   echo "$HOME/.kimi-code" ;;
  esac
}
agent_present() {
  case "$1" in
    claude) command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ] ;;
    codex)  command -v codex >/dev/null 2>&1 || mise which codex >/dev/null 2>&1 ;;
    cursor) command -v cursor-agent >/dev/null 2>&1 ;;
    kimi)   [ -x "$HOME/.kimi-code/bin/kimi" ] ;;
  esac
}

failed=()
installed=()
skipped=()

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
  if [ "$(uname -s)" = "Darwin" ]; then
    failed+=("herdr — not installed; run 'make brew'")
  else
    failed+=("herdr — not installed; run 'make linux-pkgs'")
  fi
else
  # `integration status` prints one line per kind:
  #   claude: current (v7) (/path/to/hook)
  #   pi: not installed (/path/to/hook)
  # Re-install anything not already current. Installing is idempotent, but
  # skipping the current ones keeps the step quiet and fast.
  status_out=$(herdr integration status 2>/dev/null || true)

  # herdr writes the claude hook with this machine's absolute $HOME into the
  # stowed, tracked settings.json, so the file would differ on every box and
  # the VM template would snapshot it dirty. Rewrite the command to the $HOME
  # form the repo commits (hooks run through a shell, so it expands at call
  # time) and drop the duplicate entry install leaves next to it. A herdr
  # release that changes the entry's shape shows up as a real diff to commit.
  normalize_claude_hook() {
    local settings="$HOME/.claude/settings.json"
    [ -f "$settings" ] && command -v python3 >/dev/null 2>&1 || return 0
    python3 - "$settings" "$HOME" <<'PY'
import json, sys
path, home = sys.argv[1], sys.argv[2]
with open(path) as f:
    data = json.load(f)
abs_cmd = f"bash '{home}/.claude/hooks/herdr-agent-state.sh' session"
rel_cmd = 'bash "$HOME/.claude/hooks/herdr-agent-state.sh" session'
changed = False
for name, group in data.get("hooks", {}).items():
    seen, kept = set(), []
    for entry in group:
        for h in entry.get("hooks", []):
            if h.get("command") == abs_cmd:
                h["command"] = rel_cmd
                changed = True
        key = json.dumps(entry, sort_keys=True)
        if key in seen:
            changed = True
            continue
        seen.add(key)
        kept.append(entry)
    data["hooks"][name] = kept
if changed:
    with open(path, "w") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("· claude hook path normalised to $HOME")
PY
  }

  for kind in "${INTEGRATIONS[@]}"; do
    case $'\n'"$status_out" in
      *$'\n'"$kind: current"*)
        echo "· $kind integration current"
        continue ;;
    esac
    dir="$(agent_dir "$kind")"
    if [ ! -d "$dir" ]; then
      if agent_present "$kind"; then
        mkdir -p "$dir"
      else
        echo "· $kind not present — skipping"
        skipped+=("$kind")
        continue
      fi
    fi
    echo "→ installing $kind integration"
    if herdr integration install "$kind" >/dev/null 2>&1; then
      installed+=("$kind")
    else
      failed+=("$kind — herdr integration install failed")
    fi
  done
  normalize_claude_hook
fi

# ── Result ──────────────────────────────────────────────────────────────────
if [ ${#failed[@]} -gt 0 ]; then
  printf '✗ %s\n' "${failed[@]}" >&2
  emit_result "herdr" "warn" "${#failed[@]} issue(s)" "${failed[@]}"
  exit 1
fi

[ ${#installed[@]} -gt 0 ] && echo "✓ installed integrations: ${installed[*]}"
current=$(( ${#INTEGRATIONS[@]} - ${#skipped[@]} ))
summary="$current integrations current"
[ ${#skipped[@]} -gt 0 ] && summary+=", ${#skipped[@]} skipped (${skipped[*]})"
echo "✓ herdr ready — config linked, $summary"
emit_result "herdr" "ok" "$summary"
