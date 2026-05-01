#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# Close any open System Preferences panes so they don't override settings.
osascript -e 'tell application "System Preferences" to quit' 2>/dev/null || true

# Cache sudo upfront, then keep alive in the background until this script ends.
sudo -v
( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &

# General UI/UX
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode  -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write com.apple.LaunchServices LSQuarantine              -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Keyboard
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain KeyRepeat                -int 1
defaults write NSGlobalDomain InitialKeyRepeat         -int 10

# Finder
defaults write com.apple.finder AppleShowAllFiles            -bool true
defaults write NSGlobalDomain   AppleShowAllExtensions        -bool true
defaults write com.apple.finder ShowStatusBar                -bool true
defaults write com.apple.finder ShowPathbar                  -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle      -bool true
defaults write com.apple.finder _FXSortFoldersFirst          -bool true
defaults write com.apple.finder FXDefaultSearchScope         -string "SCcf"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Dock
defaults write com.apple.dock tilesize -int 32

# .DS_Store hygiene
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores     -bool true

# Power
sudo pmset -c sleep 0
sudo pmset -b sleep 5

# Security
defaults write com.apple.screensaver askForPassword       -int 1
defaults write com.apple.screensaver askForPasswordDelay  -int 0

# Screenshots
defaults write com.apple.screencapture type -string "png"

# Mail
defaults write com.apple.mail AddressesIncludeNameOnPasteboard -bool false
defaults write com.apple.mail DraftsViewerAttributes -dict-add "DisplayInThreadedMode" -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortedDescending"      -string "yes"
defaults write com.apple.mail DraftsViewerAttributes -dict-add "SortOrder"             -string "received-date"
defaults write com.apple.mail DisableInlineAttachmentViewing   -bool true

# App Store
defaults write com.apple.appstore       WebKitDeveloperExtras -bool true
defaults write com.apple.appstore       ShowDebugMenu         -bool true
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate ScheduleFrequency     -int 1
defaults write com.apple.SoftwareUpdate AutomaticDownload     -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
defaults write com.apple.SoftwareUpdate ConfigDataInstall     -int 1
defaults write com.apple.commerce       AutoUpdate                 -bool true
defaults write com.apple.commerce       AutoUpdateRestartRequired  -bool true

echo "Defaults applied. Some changes require a Finder/Dock restart or logout."
emit_result "defaults" "ok" "applied"
