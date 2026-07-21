#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# --verify: read back every setting instead of writing it, print a one-line
# summary, exit non-zero on any mismatch. status.sh uses this as the live
# probe — the same dw lines drive both apply and verify, so probe coverage
# can't drift from what the step actually does.
VERIFY=0
[ "${1:-}" = "--verify" ] && VERIFY=1

if [ "$VERIFY" -eq 0 ]; then
  # Close any open System Preferences panes so they don't override settings.
  osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

  # Cache sudo upfront, then keep alive in the background until this script ends.
  sudo -v
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
fi

# dw — `defaults write` that records failures instead of aborting the step.
# Sandboxed domains (Mail, App Store) live in ~/Library/Containers and can't
# be written unless the terminal has Full Disk Access; one blocked domain
# shouldn't kill every setting after it.
FAILED=()
TOTAL=0
SKIPPED=0
dw() {
  TOTAL=$((TOTAL + 1))
  if [ "$VERIFY" -eq 1 ]; then
    local domain="$1" key="$2" type="${3:-}" want="${4:-}" got
    case "$type" in
      -dict-add)
        # No cheap read-back for a single dict entry; not counted either way.
        TOTAL=$((TOTAL - 1)); SKIPPED=$((SKIPPED + 1)); return 0 ;;
      -bool)
        case "$want" in true) want=1 ;; false) want=0 ;; esac ;;
    esac
    if ! got=$(defaults read "$domain" "$key" 2>/dev/null); then
      FAILED+=("$domain $key — not set")
    elif [ "$got" != "$want" ]; then
      FAILED+=("$domain $key — want $want, got $got")
    fi
    return 0
  fi
  local err
  if ! err=$(defaults write "$@" 2>&1); then
    FAILED+=("$1 $2 — ${err//$'\n'/ }")
  fi
}

# General UI/UX
dw NSGlobalDomain NSNavPanelExpandedStateForSaveMode  -bool true
dw NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
dw com.apple.LaunchServices LSQuarantine              -bool false
dw NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Keyboard
dw NSGlobalDomain ApplePressAndHoldEnabled -bool false
dw NSGlobalDomain KeyRepeat                -int 1
dw NSGlobalDomain InitialKeyRepeat         -int 10

# Finder
dw com.apple.finder AppleShowAllFiles            -bool true
dw NSGlobalDomain   AppleShowAllExtensions        -bool false
dw com.apple.finder ShowStatusBar                -bool true
dw com.apple.finder ShowPathbar                  -bool true
dw com.apple.finder _FXShowPosixPathInTitle      -bool true
dw com.apple.finder _FXSortFoldersFirst          -bool true
dw com.apple.finder FXDefaultSearchScope         -string "SCcf"
dw com.apple.finder FXEnableExtensionChangeWarning -bool false

# Dock
dw com.apple.dock tilesize -int 32

# .DS_Store hygiene
dw com.apple.desktopservices DSDontWriteNetworkStores -bool true
dw com.apple.desktopservices DSDontWriteUSBStores     -bool true

# Power
if [ "$VERIFY" -eq 1 ]; then
  pm_sleep() {
    pmset -g custom 2>/dev/null \
      | awk -v sec="$1" '$0 == sec" Power:" {insec=1; next} /Power:/ {insec=0} insec && $1 == "sleep" {print $2; exit}'
  }
  TOTAL=$((TOTAL + 2))
  [ "$(pm_sleep "AC")" = "0" ]      || FAILED+=("pmset AC sleep — want 0, got $(pm_sleep "AC")")
  [ "$(pm_sleep "Battery")" = "5" ] || FAILED+=("pmset Battery sleep — want 5, got $(pm_sleep "Battery")")
else
  sudo pmset -c sleep 0
  sudo pmset -b sleep 5
fi

# Security
dw com.apple.screensaver askForPassword       -int 1
dw com.apple.screensaver askForPasswordDelay  -int 0

# Screenshots
dw com.apple.screencapture type -string "png"

# Mail
dw com.apple.mail AddressesIncludeNameOnPasteboard -bool false
dw com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
dw com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending"      -string "yes"
dw com.apple.mail DraftsViewerAttributes -dict-add "SortOrder"             -string "received-date"
dw com.apple.mail DisableInlineAttachmentViewing   -bool true

# App Store
dw com.apple.appstore       WebKitDeveloperExtras -bool true
dw com.apple.appstore       ShowDebugMenu         -bool true
dw com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
dw com.apple.SoftwareUpdate ScheduleFrequency     -int 1
dw com.apple.SoftwareUpdate AutomaticDownload     -int 1
dw com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
dw com.apple.SoftwareUpdate ConfigDataInstall     -int 1
dw com.apple.commerce       AutoUpdate                 -bool true
dw com.apple.commerce       AutoUpdateRestartRequired  -bool true

if [ "$VERIFY" -eq 1 ]; then
  summary="$((TOTAL - ${#FAILED[@]}))/$TOTAL defaults match"
  [ "$SKIPPED" -gt 0 ] && summary="$summary ($SKIPPED unverifiable)"
  echo "$summary"
  if [ ${#FAILED[@]} -gt 0 ]; then
    printf '    %s\n' "${FAILED[@]}" >&2
    exit 1
  fi
  exit 0
fi

if [ ${#FAILED[@]} -eq 0 ]; then
  echo "Defaults applied. Some changes require a Finder/Dock restart or logout."
  emit_result "defaults" "ok" "applied"
else
  echo "⚠ ${#FAILED[@]} of $TOTAL defaults could not be written:"
  printf '    %s\n' "${FAILED[@]}"
  echo ""
  echo "Sandboxed domains (Mail, App Store) need Full Disk Access for your"
  echo "terminal. Open the pane directly with:"
  echo "  open \"x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles\""
  echo "Toggle your terminal on (+ to add it), quit it fully (⌘Q), reopen,"
  echo "then re-run: make -C ~/dotfiles/scripts defaults"
  emit_result "defaults" "warn" "$((TOTAL - ${#FAILED[@]}))/$TOTAL applied" "${FAILED[@]}"
fi
