#!/usr/bin/env bash
# Tests for the pure-logic parts of the setup scripts: status.sh probes and
# defaults.sh --verify. Installer steps (brew, curl, launchctl) are exercised
# by the weekly drift probes on real machines, not here.
#
# Technique: each test builds a throwaway $HOME (and runs against a sandboxed
# git copy of the repo, so repo-state tests can dirty it at will) and asserts
# on probe output. Stubbed `defaults`/`pmset`/`sudo` make the defaults
# round-trip deterministic on any machine, including CI.
set -uo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0 FAIL=0
t_ok()   { PASS=$((PASS + 1)); printf '  ✓ %s\n' "$1"; }
t_fail() { FAIL=$((FAIL + 1)); printf '  ✗ %s\n      expected: %s\n      got:      %s\n' "$1" "$2" "$3"; }

assert_contains() { # <name> <haystack> <needle>
  case "$2" in
    *"$3"*) t_ok "$1" ;;
    *)      t_fail "$1" "…$3…" "$2" ;;
  esac
}

assert_lacks() { # <name> <haystack> <needle>
  case "$2" in
    *"$3"*) t_fail "$1" "no …$3…" "$2" ;;
    *)      t_ok "$1" ;;
  esac
}

assert_rc() { # <name> <want> <got>
  if [ "$2" -eq "$3" ]; then t_ok "$1"; else t_fail "$1" "rc=$2" "rc=$3"; fi
}

# ── Sandbox repo ─────────────────────────────────────────────────────────────
# Probes derive DOTFILES_DIR from their own location, so copy the scripts into
# a disposable git repo.
SANDBOX="$WORK/repo"
mkdir -p "$SANDBOX"
cp -R "$DOTFILES_DIR/scripts" "$SANDBOX/scripts"
cp -R "$DOTFILES_DIR/launchagents" "$SANDBOX/launchagents"
git -C "$SANDBOX" init -q
git -C "$SANDBOX" -c user.name=t -c user.email=t@t add -A
git -C "$SANDBOX" -c user.name=t -c user.email=t@t commit -qm init

STATUS="$SANDBOX/scripts/setup/status.sh"
DEFAULTS="$SANDBOX/scripts/setup/defaults.sh"

new_home() { mkdir -p "$WORK/home-$1"; printf '%s' "$WORK/home-$1"; }

# Fast stubs for probes we're not testing: the real brew/mise/defaults calls
# cost ~20s per status run and none of the probe tests below depend on them.
PROBESTUBS="$WORK/probestubs"
mkdir -p "$PROBESTUBS"
for stub in brew mise defaults; do
  printf '#!/usr/bin/env bash\nexit 1\n' > "$PROBESTUBS/$stub"
done
printf '#!/usr/bin/env bash\nexit 0\n' > "$PROBESTUBS/pmset"
chmod +x "$PROBESTUBS"/*

status_out() { # <home> [PATH override]
  HOME="$1" PATH="$PROBESTUBS:${2:-$PATH}" bash "$STATUS" 2>/dev/null
}

# ── agents (LaunchAgents) probe ──────────────────────────────────────────────
echo "agents probe:"

H=$(new_home agents-folded)
mkdir -p "$H/Library"
ln -s "$SANDBOX/launchagents/Library/LaunchAgents" "$H/Library/LaunchAgents"
assert_contains "stow-folded dir → fail (launchd skips symlinked dirs)" \
  "$(status_out "$H" | grep 'LaunchAgents')" "launchd skips it at login"

H=$(new_home agents-linked)
mkdir -p "$H/Library/LaunchAgents"
for p in "$SANDBOX"/launchagents/Library/LaunchAgents/*.plist; do
  ln -s "$p" "$H/Library/LaunchAgents/$(basename "$p")"
done
assert_contains "all plists linked → ok" \
  "$(status_out "$H" | grep 'LaunchAgents')" "2 plist(s) linked"

rm "$H/Library/LaunchAgents/com.vladsuciu.keyremap.plist"
assert_contains "one plist missing → fail" \
  "$(status_out "$H" | grep 'LaunchAgents')" "1 of 2 plist(s) not linked"

# ── ai-clis probe ────────────────────────────────────────────────────────────
# PATH stripped to system dirs so real installs (~/.local/bin, brew, mise)
# can't leak in.
echo "ai-clis probe:"
LEAN_PATH="/usr/bin:/bin"

H=$(new_home clis-none)
assert_contains "nothing installed → fail all three" \
  "$(status_out "$H" "$LEAN_PATH" | grep 'AI CLIs')" "missing: claude codex kimi"

H=$(new_home clis-all)
mkdir -p "$H/.local/bin" "$H/.kimi-code/bin" "$WORK/fakebin"
touch "$H/.local/bin/claude" "$H/.kimi-code/bin/kimi" "$WORK/fakebin/codex"
chmod +x "$H/.local/bin/claude" "$H/.kimi-code/bin/kimi" "$WORK/fakebin/codex"
assert_contains "all present → ok" \
  "$(status_out "$H" "$WORK/fakebin:$LEAN_PATH" | grep 'AI CLIs')" "claude, codex, kimi present"

# ── herdr probe ──────────────────────────────────────────────────────────────
# The "herdr absent" case isn't tested: the probe falls back to absolute brew
# paths for the drift agent's bare PATH, so on a machine with herdr installed
# no PATH manipulation can hide it. The three cases below are deterministic.
echo "herdr probe:"

H=$(new_home herdr-folded)
mkdir -p "$H/.config"
ln -s "$SANDBOX/herdr/.config/herdr" "$H/.config/herdr"
assert_contains "stow-folded config dir → fail" \
  "$(status_out "$H" | grep 'herdr')" "is a symlink"

# Stub herdr on PATH so integration state is deterministic. Mirrors the real
# `integration status` format: "<kind>: current (vN) (/path)".
HERDRBIN="$WORK/herdrbin"
mkdir -p "$HERDRBIN"
cat > "$HERDRBIN/herdr" <<'STUB'
#!/usr/bin/env bash
[ "${3:-}" = "--outdated-only" ] && exit 0
for k in claude codex cursor kimi; do
  if [ "$k" = "${HERDR_TEST_STALE:-}" ]; then
    echo "$k: not installed (/tmp/$k)"
  else
    echo "$k: current (v7) (/tmp/$k)"
  fi
done
STUB
chmod +x "$HERDRBIN/herdr"

# Agent config dirs present: the probe only expects an integration for an
# agent that is installed or has been run (same rule as herdr.sh).
H=$(new_home herdr-ok)
mkdir -p "$H/.config/herdr" "$H/.claude" "$H/.codex" "$H/.cursor" "$H/.kimi-code"
assert_contains "all integrations current → ok" \
  "$(status_out "$H" "$HERDRBIN:$LEAN_PATH" | grep 'herdr')" "4 integrations current"

H=$(new_home herdr-stale)
mkdir -p "$H/.config/herdr" "$H/.claude" "$H/.codex" "$H/.cursor" "$H/.kimi-code"
assert_contains "an integration not current → fail, named" \
  "$(HERDR_TEST_STALE=codex status_out "$H" "$HERDRBIN:$LEAN_PATH" | grep 'herdr')" \
  "integration(s) not current: codex"

# No ~/.cursor and no cursor-agent on the lean PATH → not expected, not drift.
H=$(new_home herdr-skip)
mkdir -p "$H/.config/herdr" "$H/.claude" "$H/.codex" "$H/.kimi-code"
assert_contains "absent agent → skipped, not drift" \
  "$(HERDR_TEST_STALE=cursor status_out "$H" "$HERDRBIN:$LEAN_PATH" | grep 'herdr')" \
  "3 integrations current, skipped: cursor"

# ── repo probe ───────────────────────────────────────────────────────────────
echo "repo probe:"

H=$(new_home repo)
assert_contains "clean sandbox → ok" \
  "$(status_out "$H" | grep 'Dotfiles repo')" "clean, in sync with origin"

touch "$SANDBOX/untracked-file"
assert_contains "untracked file → warn" \
  "$(status_out "$H" | grep 'Dotfiles repo')" "1 uncommitted change(s)"
rm "$SANDBOX/untracked-file"

# ── --check mode ─────────────────────────────────────────────────────────────
echo "--check mode:"

H=$(new_home check)
check_out=$(HOME="$H" PATH="$PROBESTUBS:$LEAN_PATH" bash "$STATUS" --check 2>/dev/null); check_rc=$?
assert_rc "drift present → exit 1" 1 "$check_rc"
assert_contains "drift lines name the step" "$check_out" "AI CLIs: missing:"

# ── off macOS ────────────────────────────────────────────────────────────────
# status.sh and `make check` audit install.sh's chain (brew, defaults,
# launchd), which never runs on the Linux VMs — there they must decline, not
# report five steps that can't exist as "never ran" and advise 'make brew'.
# A `uname` stub in its own dir so no other test sees it.
echo "off macOS:"
LINUXSTUB="$WORK/linuxstub"
mkdir -p "$LINUXSTUB"
printf '#!/usr/bin/env bash\necho Linux\n' > "$LINUXSTUB/uname"
chmod +x "$LINUXSTUB/uname"

H=$(new_home linux)
linux_out=$(HOME="$H" PATH="$LINUXSTUB:$PROBESTUBS:$LEAN_PATH" bash "$STATUS" 2>&1); linux_rc=$?
assert_rc "status off macOS → exit 1" 1 "$linux_rc"
assert_contains "status off macOS → declines, points at make linux" "$linux_out" "macOS only"
assert_contains "status off macOS → points at make linux" "$linux_out" "make linux"
assert_lacks "status off macOS → no step report" "$linux_out" "Install status"

linux_check=$(HOME="$H" PATH="$LINUXSTUB:$PROBESTUBS:$LEAN_PATH" bash "$STATUS" --check 2>&1); linux_check_rc=$?
assert_rc "status --check off macOS → exit 1" 1 "$linux_check_rc"
assert_contains "status --check off macOS → declines, not a drift list" "$linux_check" "macOS only"

make_check=$(HOME="$H" PATH="$LINUXSTUB:$PROBESTUBS:$LEAN_PATH" make -s -C "$SANDBOX/scripts" check 2>&1); make_check_rc=$?
if [ "$make_check_rc" -ne 0 ]; then t_ok "make check off macOS → non-zero"; else t_fail "make check off macOS → non-zero" "rc≠0" "rc=0"; fi
assert_contains "make check off macOS → declines before the audit" "$make_check" "macOS only"
assert_lacks "make check off macOS → no audit sections" "$make_check" "Required commands"

# ── github_ssh_auth_ok (ssh.sh) ──────────────────────────────────────────────
# GitHub greets then closes, so `ssh -T` exits 1 on success and only the
# greeting says it worked. ssh.sh runs under pipefail, where an
# `ssh | grep -q` check reports every success as a failure — the drift probes
# can't catch that because the path only runs on a machine cloned over HTTPS.
# The stub mirrors GitHub's real output; the helper runs under ssh.sh's own
# shell options so the test sees exactly what the script sees.
echo "github_ssh_auth_ok:"
LIB="$SANDBOX/scripts/setup/_lib.sh"
SSHSTUB="$WORK/sshstub"
mkdir -p "$SSHSTUB"
cat > "$SSHSTUB/ssh" <<'STUB'
#!/usr/bin/env bash
if [ "${SSH_TEST_DENY:-}" = 1 ]; then
  echo "git@github.com: Permission denied (publickey)." >&2
  exit 255
fi
echo "Hi t! You've successfully authenticated, but GitHub does not provide shell access." >&2
exit 1
STUB
chmod +x "$SSHSTUB/ssh"

auth_check() { PATH="$SSHSTUB:$LEAN_PATH" bash -euo pipefail -c '. "$1"; github_ssh_auth_ok' _ "$LIB"; }

auth_check; assert_rc "greeting + exit 1 → authenticated (rc 0)" 0 "$?"
SSH_TEST_DENY=1 auth_check; assert_rc "permission denied → not authenticated (rc 1)" 1 "$?"

# ── defaults.sh apply → verify round-trip ────────────────────────────────────
# Stub defaults/pmset/sudo/osascript: `write` records normalized values the
# way macOS would (bool → 1/0), `read` returns them. Apply then verify must
# agree 100% — if the two interpretations of the same dw lines ever diverge,
# this fails.
echo "defaults --verify:"

STUBS="$WORK/stubs"
mkdir -p "$STUBS"

cat > "$STUBS/defaults" <<'EOF'
#!/usr/bin/env bash
db="${DEFAULTS_DB:?}"
cmd="$1"; shift
case "$cmd" in
  write)
    domain="$1" key="$2" type="${3:-}" val="${4:-}"
    case "$type" in
      -bool) case "$val" in true) val=1 ;; false) val=0 ;; esac ;;
      -dict-add) exit 0 ;;
    esac
    printf '%s\t%s\t%s\n' "$domain" "$key" "$val" >> "$db" ;;
  read)
    prefix="$(printf '%s\t%s\t' "$1" "$2")"
    line=$(grep -F "$prefix" "$db" 2>/dev/null | tail -1)
    [ -n "$line" ] || exit 1
    printf '%s\n' "${line##*	}" ;;
esac
EOF

cat > "$STUBS/pmset" <<'EOF'
#!/usr/bin/env bash
if [ "${1:-}" = "-g" ]; then
  printf 'Battery Power:\n sleep\t5\nAC Power:\n sleep\t0\n'
fi
exit 0
EOF

cat > "$STUBS/sudo" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in -v|-n) exit 0 ;; esac
exec "$@"
EOF

printf '#!/usr/bin/env bash\nexit 0\n' > "$STUBS/osascript"
chmod +x "$STUBS/defaults" "$STUBS/pmset" "$STUBS/sudo" "$STUBS/osascript"

H=$(new_home defaults)
DB="$H/defaults-db"

apply_out=$(DEFAULTS_DB="$DB" PATH="$STUBS:$PATH" bash "$DEFAULTS" 2>&1); apply_rc=$?
assert_rc "apply succeeds against stubs" 0 "$apply_rc"
assert_contains "apply reports success" "$apply_out" "Defaults applied."

verify_out=$(DEFAULTS_DB="$DB" PATH="$STUBS:$PATH" bash "$DEFAULTS" --verify 2>&1); verify_rc=$?
assert_rc "verify passes after apply" 0 "$verify_rc"
assert_contains "dict-add entries counted as unverifiable" "$verify_out" "(3 unverifiable)"

matched="${verify_out%%/*}"
total="${verify_out#*/}"; total="${total%% *}"
if [ -n "$matched" ] && [ "$matched" = "$total" ]; then
  t_ok "round-trip is total: $matched/$total"
else
  t_fail "round-trip is total" "N/N" "$verify_out"
fi

# Drift one recorded value → verify must catch exactly that key.
sed -i.bak 's/^com.apple.dock	tilesize	32$/com.apple.dock	tilesize	40/' "$DB"
drift_out=$(DEFAULTS_DB="$DB" PATH="$STUBS:$PATH" bash "$DEFAULTS" --verify 2>&1); drift_rc=$?
assert_rc "drifted value → exit 1" 1 "$drift_rc"
assert_contains "drift names the key" "$drift_out" "com.apple.dock tilesize — want 32, got 40"

# ── codex package ────────────────────────────────────────────────────────────
# ~/.codex holds auth.json and session sqlite; the package links only AGENTS.md
# (a symlink to claude/.claude/CLAUDE.md). Two guards keep that runtime state
# out of the repo: the .gitignore rule, and bootstrap.sh / stow-linux
# pre-creating ~/.codex so stow links per-file instead of folding the dir.
# Both are checked against the real repo, read-only (check-ignore, stow -n).
echo "codex package:"

assert_contains "AGENTS.md → claude/.claude/CLAUDE.md" \
  "$(readlink "$DOTFILES_DIR/codex/.codex/AGENTS.md")" "claude/.claude/CLAUDE.md"
ignored() { git -C "$DOTFILES_DIR" check-ignore -q "$1" && echo ignored || echo tracked; }
assert_contains "codex/.codex/auth.json ignored" "$(ignored codex/.codex/auth.json)" "ignored"
assert_contains "codex/.codex/AGENTS.md tracked" "$(ignored codex/.codex/AGENTS.md)" "tracked"

if command -v stow >/dev/null 2>&1; then
  H=$(new_home codex)
  mkdir -p "$H/.codex"
  assert_contains "pre-created ~/.codex → per-file link" \
    "$(stow -n -v -t "$H" -d "$DOTFILES_DIR" codex 2>&1)" "LINK: .codex/AGENTS.md"
  H=$(new_home codex-fold)
  assert_contains "missing ~/.codex → stow folds it (why bootstrap pre-creates)" \
    "$(stow -n -v -t "$H" -d "$DOTFILES_DIR" codex 2>&1)" "LINK: .codex =>"
else
  echo "  · stow not installed — dry-run checks skipped"
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
