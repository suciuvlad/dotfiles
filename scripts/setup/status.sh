#!/usr/bin/env bash
# make status — what the install chain has done, what's pending, and how to
# resume. Reads the persistent per-step results install.sh appends to
# ~/.local/state/dotfiles/results.jsonl, then cross-checks each step against
# the live machine (a recorded "ok" is a claim; the probe is the evidence).
# Always exits 0 — this is a report, not a gate.
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DOTFILES_DIR="$(cd "$SCRIPTS_DIR/.." && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles"
RESULTS="$STATE_DIR/results.jsonl"

# Chain order must match install.sh. TARGETS maps step ids to make targets
# (both brew steps re-run via `make brew`).
STEPS=(brew-strict brew-optional ssh runtimes defaults iterm agents agent-skills)
LABELS=("Homebrew (strict)" "Homebrew (optional)" "SSH key" "Runtimes (mise)" "macOS defaults" "iTerm2 integration" "LaunchAgents" "Agent skills")
TARGETS=(brew brew ssh runtimes defaults iterm agents skills)

icon() {
  case "$1" in
    ok)    printf '\033[32m✓\033[0m' ;;
    warn)  printf '\033[33m⚠\033[0m' ;;
    fail)  printf '\033[31m✗\033[0m' ;;
    never) printf '\033[90m∅\033[0m' ;;
    *)     printf '?' ;;
  esac
}

# Latest recorded value of <field> for <step>. Empty when never recorded.
latest_field() {
  [ -f "$RESULTS" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg id "$1" --arg f "$2" \
      'select(.step==$id) | .[$f] // empty' "$RESULTS" 2>/dev/null | tail -1
  else
    # `|| true` keeps a no-match grep from killing the pipeline under -e/pipefail.
    { grep "\"step\":\"$1\"" "$RESULTS" 2>/dev/null || true; } | tail -1 \
      | sed -nE "s/.*\"$2\":\"([^\"]*)\".*/\1/p"
  fi
}

latest_ts() {
  [ -f "$RESULTS" ] || return 0
  { grep "\"step\":\"$1\"" "$RESULTS" 2>/dev/null || true; } | tail -1 \
    | sed -nE 's/.*"ts":([0-9]+).*/\1/p'
}

age() {  # humanize seconds-since-epoch → "5m ago"
  local d=$(( $(date +%s) - $1 ))
  if   [ "$d" -lt 60 ];    then printf '%ds ago' "$d"
  elif [ "$d" -lt 3600 ];  then printf '%dm ago' $((d / 60))
  elif [ "$d" -lt 86400 ]; then printf '%dh ago' $((d / 3600))
  else                          printf '%dd ago' $((d / 86400))
  fi
}

# Live probes. Each echoes "<ok|warn|fail> <note>"; steps without a cheap,
# reliable check (defaults, brew-optional) echo nothing and the recorded
# status stands alone.
probe() {
  case "$1" in
    brew-strict)
      if ! command -v brew >/dev/null 2>&1; then
        echo "fail brew not installed"
      elif brew bundle check --no-upgrade --file="$SCRIPTS_DIR/Brewfile" >/dev/null 2>&1; then
        echo "ok Brewfile satisfied"
      else
        echo "fail Brewfile packages missing"
      fi ;;
    ssh)
      # ssh exits 1 even on successful auth, so under pipefail a
      # `ssh | grep` pipeline can never succeed — capture, then match.
      local ssh_out
      if [ ! -f "$HOME/.ssh/id_ed25519" ]; then
        echo "fail no key at ~/.ssh/id_ed25519"
      else
        ssh_out=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new \
                      -T git@github.com 2>&1 || true)
        case "$ssh_out" in
          *"successfully authenticated"*) echo "ok GitHub auth works" ;;
          *) echo "warn key exists but GitHub rejects it — register it" ;;
        esac
      fi ;;
    runtimes)
      if ! command -v mise >/dev/null 2>&1; then
        echo "fail mise not installed"
      else
        local missing
        missing=$(cd "$HOME" && mise ls 2>/dev/null | grep -c missing || true)
        if [ "$missing" -eq 0 ]; then
          echo "ok all runtimes installed"
        else
          echo "fail $missing runtime(s) missing"
        fi
      fi ;;
    iterm)
      if [ -f "$HOME/.iterm2_shell_integration.zsh" ]; then
        echo "ok integration script present"
      else
        echo "fail ~/.iterm2_shell_integration.zsh missing"
      fi ;;
    agents)
      local plist missing_agents=0 total=0
      for plist in "$DOTFILES_DIR"/launchagents/Library/LaunchAgents/*.plist; do
        [ -e "$plist" ] || continue
        total=$((total + 1))
        [ -e "$HOME/Library/LaunchAgents/$(basename "$plist")" ] || missing_agents=$((missing_agents + 1))
      done
      if [ "$total" -eq 0 ]; then
        echo "ok no LaunchAgents defined"
      elif [ "$missing_agents" -eq 0 ]; then
        echo "ok $total plist(s) linked"
      else
        echo "fail $missing_agents of $total plist(s) not linked"
      fi ;;
    agent-skills)
      # Mirror agent-skills.sh semantics: absent agent dirs are skipped there,
      # so they can't count as failures here.
      if [ ! -d "$HOME/.agents/skills" ]; then
        echo "fail skill store ~/.agents/skills missing (stow agents first)"
      else
        local agent_dir agents_present=0 unlinked=""
        for agent_dir in "$HOME/.cursor" "$HOME/.codex"; do
          [ -d "$agent_dir" ] || continue
          agents_present=$((agents_present + 1))
          [ -d "$agent_dir/skills" ] || unlinked="$unlinked ~/${agent_dir##*/}/skills"
        done
        if [ "$agents_present" -eq 0 ]; then
          echo "ok no agent dirs present — nothing to link"
        elif [ -z "$unlinked" ]; then
          echo "ok skill links present"
        else
          echo "fail missing:$unlinked"
        fi
      fi ;;
  esac
}

# ── Report ──────────────────────────────────────────────────────────────────
echo ""
echo "── Install status ────────────────────────────────────────────────"
[ -f "$RESULTS" ] || echo "  (no recorded runs yet — showing live probes only)"

PENDING_TARGETS=()   # make targets still needing a run, chain order
REGISTER_KEY=0

for i in "${!STEPS[@]}"; do
  step="${STEPS[i]}"
  recorded=$(latest_field "$step" "status")
  detail=$(latest_field "$step" "detail")
  ts=$(latest_ts "$step")

  if [ -n "$recorded" ]; then
    rec_str="$recorded"
    [ -n "$detail" ] && rec_str="$rec_str — $detail"
    [ -n "$ts" ] && rec_str="$rec_str ($(age "$ts"))"
  else
    recorded="never"
    rec_str="never ran"
  fi

  live=$(probe "$step")
  live_status="${live%% *}"
  live_note="${live#* }"

  # The live probe outranks the record in both directions; without a probe,
  # the record stands.
  effective="$recorded"
  if [ -n "$live" ]; then
    effective="$live_status"
    printf "  %s %-22s %-34s live: %s\n" \
      "$(icon "$effective")" "${LABELS[i]}" "$rec_str" "$live_note"
  else
    printf "  %s %-22s %s\n" "$(icon "$effective")" "${LABELS[i]}" "$rec_str"
  fi

  case "$effective" in
    fail|never) PENDING_TARGETS+=("${TARGETS[i]}") ;;
  esac
  if [ "$step" = "ssh" ] && [ "$live_status" = "warn" ]; then
    REGISTER_KEY=1
  fi
done

# ── Next steps ──────────────────────────────────────────────────────────────
NEXT=()

if [ "$REGISTER_KEY" -eq 1 ]; then
  NEXT+=("Register ~/.ssh/id_ed25519.pub at https://github.com/settings/keys
      as BOTH an Authentication Key and a Signing Key, then re-run:
        make -C $SCRIPTS_DIR ssh")
fi

# Casks that failed because the app was already in /Applications → adopt them.
if command -v jq >/dev/null 2>&1 && [ -f "$RESULTS" ]; then
  adopt=$(jq -s -r '[.[] | select(.step=="brew-optional")] | last | .failures[]?' \
            "$RESULTS" 2>/dev/null \
          | sed -nE 's/^cask ([[:alnum:]@_-]+) — Error: It seems there is already an App.*/\1/p' \
          | tr '\n' ' ')
  if [ -n "${adopt// /}" ]; then
    NEXT+=("Adopt pre-installed apps so brew manages them:
        brew install --cask --adopt ${adopt% }")
  fi
fi

if [ ${#PENDING_TARGETS[@]} -gt 0 ]; then
  # Dedup while preserving chain order (brew maps from two steps).
  deduped=""
  for t in "${PENDING_TARGETS[@]}"; do
    case " $deduped " in *" $t "*) ;; *) deduped="$deduped $t" ;; esac
  done
  NEXT+=("Run the remaining step(s):
        make -C $SCRIPTS_DIR${deduped}")
fi

echo ""
if [ ${#NEXT[@]} -eq 0 ]; then
  echo "  Nothing pending — the install chain is complete."
else
  echo "── Next steps ─────────────────────────────────────────────────────"
  n=1
  for item in "${NEXT[@]}"; do
    printf "  %d. %s\n" "$n" "$item"
    n=$((n + 1))
  done
fi
echo ""
echo "  State: $RESULTS"
echo "  Log:   ${DOTFILES_INSTALL_LOG:-$STATE_DIR/install.log}"
exit 0
