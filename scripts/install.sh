#!/usr/bin/env bash
# Orchestrator for the full install. Replaces `make all` with a UX that has
# per-step spinners, captured logs, and a final styled summary.
#
# Bypass: VERBOSE=1, non-TTY, or no gum (yet) → falls back to a plain make
# chain so first-run / CI / pipes still work.
#
# Each setup script appends a JSONL line to $INSTALL_RESULT_FILE via
# emit_result() in setup/_lib.sh. The orchestrator merges those with
# step durations to produce the summary.
set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
SCRIPTS_DIR="$DOTFILES_DIR/scripts"
SETUP_DIR="$SCRIPTS_DIR/setup"
LOG="${DOTFILES_INSTALL_LOG:-/tmp/dotfiles-install.log}"
RESULT_FILE="$(mktemp -t install-results.XXXXXX)"

export INSTALL_RESULT_FILE="$RESULT_FILE"
: > "$LOG"

# Parallel arrays — initialized up here so the EXIT trap can safely inspect
# them under `set -u` even if we abort before any step ran. (bash 3.2 has no
# associative arrays.)
STEP_IDS=()
STEP_LABELS=()
STEP_EMOJIS=()
STEP_STATUSES=()
STEP_DURATIONS=()

# Render the final summary (always — even on early abort) and clean up.
# render_summary is defined later, after the helpers it depends on.
# shellcheck disable=SC2329  # invoked indirectly via the EXIT trap below
on_exit() {
  local rc=$?
  if [ "${#STEP_IDS[@]}" -gt 0 ]; then
    render_summary
  fi
  rm -f "$RESULT_FILE"
  if [ -n "${SUDO_KEEPALIVE_PID:-}" ]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  fi
  exit "$rc"
}
trap on_exit EXIT

# Plain-mode fallback: run the bare make chain. Used when the user asks for
# verbose output, when stdout isn't a TTY (CI, pipes), or when the script is
# being driven by something that wants raw logs.
if [ "${VERBOSE:-0}" = "1" ] || [ ! -t 1 ]; then
  exec make -C "$SCRIPTS_DIR" brew runtimes ssh defaults iterm
fi

# Pre-flight: prime sudo so defaults.sh doesn't prompt mid-spinner.
echo "Bootstrapping dotfiles. Caching sudo (defaults.sh needs it later)..."
if ! sudo -v; then
  echo "sudo unavailable; aborting." >&2
  exit 1
fi
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
SUDO_KEEPALIVE_PID=$!

# Load brew shellenv up front so anything brew-installed (jq, gum, mise) is on
# PATH before we try to use it. Re-evaluated after brew-strict to pick up
# packages installed *during* this run.
brew_shellenv() {
  # Return 0 even when the second prefix doesn't exist — under `set -e`, a
  # short-circuited `&&` chain as the function's last command would abort.
  if [ -x /opt/homebrew/bin/brew ]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  if [ -x /usr/local/bin/brew    ]; then eval "$(/usr/local/bin/brew shellenv)"; fi
  return 0
}
brew_shellenv

START_TIME=$(date +%s)

format_dur() {
  local sec="$1"
  if [ "$sec" -lt 60 ]; then
    printf "%ds" "$sec"
  else
    printf "%dm %02ds" "$((sec / 60))" "$((sec % 60))"
  fi
}

# Plain icons; color codes don't survive `gum style`'s text-mode processing
# in the summary box. Pre-step headers do their own coloring directly.
status_icon() {
  case "$1" in
    ok)   printf '✓' ;;
    warn) printf '⚠' ;;
    fail) printf '✗' ;;
    *)    printf '?' ;;
  esac
}

# Used only for pre-step headers (printed directly to the terminal, not
# round-tripped through gum style).
status_icon_color() {
  case "$1" in
    ok)   printf '\033[32m✓\033[0m' ;;
    warn) printf '\033[33m⚠\033[0m' ;;
    fail) printf '\033[31m✗\033[0m' ;;
    *)    printf '?' ;;
  esac
}

# Look up the latest emit_result line for a step from the JSONL state file.
# Falls back to grep+sed when jq isn't on PATH yet (true on first run before
# brew-strict installs it).
lookup_field() {  # lookup_field <step_id> <field>
  local step_id="$1" field="$2"
  if command -v jq >/dev/null 2>&1; then
    jq -r --arg id "$step_id" --arg f "$field" \
      'select(.step==$id) | .[$f]' "$RESULT_FILE" 2>/dev/null \
      | tail -1
  else
    grep "\"step\":\"$step_id\"" "$RESULT_FILE" 2>/dev/null \
      | tail -1 \
      | sed -nE "s/.*\"$field\":\"([^\"]*)\".*/\1/p"
  fi
}

# _run_with_spinner <title> <log> <cmd...>
#   Runs cmd through `gum spin`, redirecting stdout+stderr to log.
_run_with_spinner() {
  local title="$1" log="$2"; shift 2
  # shellcheck disable=SC2016  # $log/$@ are for the inner bash -c, must stay literal
  gum spin --spinner dot --title "$title" -- \
    bash -c 'log="$1"; shift; "$@" >> "$log" 2>&1' _ "$log" "$@"
}

# _run_streaming <log> <cmd...>
#   Runs cmd, tee'ing its output both to the terminal and to the log.
_run_streaming() {
  local log="$1"; shift
  set -o pipefail
  "$@" 2>&1 | tee -a "$log"
  return "${PIPESTATUS[0]}"
}

# run_step <emoji> <label> <step-id> <stream:0|1> <cmd...>
run_step() {
  local emoji="$1" label="$2" step_id="$3" stream="$4"; shift 4
  local start end dur status

  start=$(date +%s)
  printf "\n%s %s\n" "$emoji" "$label"

  if [ "$stream" = "1" ] || ! command -v gum >/dev/null 2>&1; then
    if _run_streaming "$LOG" "$@"; then status="ok"; else status="fail"; fi
  else
    if _run_with_spinner "$label..." "$LOG" "$@"; then status="ok"; else status="fail"; fi
  fi

  end=$(date +%s); dur=$((end - start))

  # If the underlying script emitted its own result (ok/warn/fail), trust
  # it over the raw exit code — scripts can express "warn" (e.g.,
  # brew-optional with a few failures) which exit-code logic can't.
  # If nothing was emitted, synthesize a minimal record so the summary
  # still has a row for this step.
  local emitted
  emitted=$(lookup_field "$step_id" "status")
  if [ -n "$emitted" ]; then
    status="$emitted"
  else
    local synth_detail
    case "$status" in
      ok)   synth_detail="completed" ;;
      fail) synth_detail="exited non-zero" ;;
      *)    synth_detail="$status" ;;
    esac
    printf '{"step":"%s","status":"%s","detail":"%s","failures":[]}\n' \
      "$step_id" "$status" "$synth_detail" >> "$RESULT_FILE"
  fi

  STEP_IDS+=("$step_id")
  STEP_LABELS+=("$label")
  STEP_EMOJIS+=("$emoji")
  STEP_STATUSES+=("$status")
  STEP_DURATIONS+=("$dur")

  printf "  %s %s — %s\n" "$(status_icon_color "$status")" "$label" "$(format_dur "$dur")"

  # Hard-stop on fail so we don't try to install runtimes after brew failed.
  # Returning non-zero under set -e propagates to the EXIT trap, which
  # renders the summary with what we have so far.
  if [ "$status" = "fail" ]; then
    printf "\nStep failed. Last 30 lines of %s:\n\n" "$LOG"
    tail -n 30 "$LOG"
    return 1
  fi
}

# Defined BEFORE the step calls so the on_exit trap can use it on early abort.
# shellcheck disable=SC2329  # invoked by on_exit trap
render_summary() {
  local end_time total_dur ok_count=0 warn_count=0 fail_count=0
  end_time=$(date +%s)
  total_dur=$((end_time - START_TIME))

  local s
  for s in "${STEP_STATUSES[@]}"; do
    case "$s" in
      ok)   ok_count=$((ok_count + 1)) ;;
      warn) warn_count=$((warn_count + 1)) ;;
      fail) fail_count=$((fail_count + 1)) ;;
    esac
  done

  local content
  content=$(_format_summary_body "$ok_count" "$warn_count" "$fail_count" "$total_dur")

  echo ""
  if command -v gum >/dev/null 2>&1; then
    gum style --border rounded --padding "1 2" --border-foreground "240" "$content"
  else
    echo "$content"
  fi
}

_format_summary_body() {
  local ok_count="$1" warn_count="$2" fail_count="$3" total_dur="$4"
  printf "Install Summary\n\n"
  local i detail dur_fmt
  for i in "${!STEP_IDS[@]}"; do
    detail=$(lookup_field "${STEP_IDS[i]}" "detail")
    dur_fmt=$(format_dur "${STEP_DURATIONS[i]}")
    # No emoji here — printf %-Ns counts bytes and mangles wide-char alignment
    # inside the boxed summary. Emojis appear in the pre-step headers instead.
    printf "  %s %-22s %-32s %8s\n" \
      "$(status_icon "${STEP_STATUSES[i]}")" \
      "${STEP_LABELS[i]}" \
      "$detail" \
      "$dur_fmt"
  done

  printf "\n  %d steps · %d ok · %d warn · %d fail · %s total\n" \
    "${#STEP_STATUSES[@]}" "$ok_count" "$warn_count" "$fail_count" \
    "$(format_dur "$total_dur")"

  if command -v jq >/dev/null 2>&1; then
    local failures
    failures=$(jq -r 'select(.failures and (.failures | length > 0))
                      | "  ⚠ " + .step + " failures:\n" +
                        ([.failures[] | "      · " + .] | join("\n"))' \
              "$RESULT_FILE" 2>/dev/null)
    if [ -n "$failures" ]; then
      printf "\n%s\n" "$failures"
    fi
  fi

  printf "\n  Logs: %s\n" "$LOG"
}

# ── Steps ───────────────────────────────────────────────────────────────────
# brew-strict comes first; everything below uses jq, gum, mise that the strict
# Brewfile installs.
# shellcheck disable=SC2016  # inner bash -c uses literal $(...) deliberately
run_step "🍺" "Homebrew (strict)" "brew-strict" 0 \
  bash -c '
    if ! command -v brew >/dev/null 2>&1; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew bundle --file="'"$SCRIPTS_DIR"'/Brewfile"
  '
# Re-eval shellenv so jq/gum installed by strict are on PATH for everything below.
brew_shellenv

# pick-optional has its own gum prompts; can't be wrapped in a spinner.
run_step "🍺" "Homebrew (optional)" "brew-optional" 1 \
  bash "$SETUP_DIR/pick-optional.sh"

run_step "🔧" "Runtimes (mise)" "runtimes" 0 \
  mise install

# ssh has an interactive ENTER prompt; must stream.
run_step "🔐" "SSH key" "ssh" 1 \
  bash "$SETUP_DIR/ssh.sh"

run_step "⚙️ " "macOS defaults" "defaults" 0 \
  bash "$SETUP_DIR/defaults.sh"

run_step "📦" "iTerm2 integration" "iterm" 0 \
  bash "$SETUP_DIR/iterm.sh"

# Falls through to the on_exit trap, which renders the summary and exits with
# whatever rc the script reached (0 here on the happy path).
