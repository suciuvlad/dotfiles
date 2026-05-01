#!/usr/bin/env bash
# Audit code-signature + Apple-notarization status of installed apps.
# Invoked from `make check`. Informational only — always exits 0.
#
# Doesn't restrict to brew-installed casks: an unsigned/un-notarized .app is
# noteworthy regardless of how it landed in /Applications.
set -uo pipefail

command -v spctl >/dev/null 2>&1 || { echo "  ⚠ spctl not available — skipping"; exit 0; }

# If Gatekeeper is disabled, `spctl --assess` would falsely report success.
if spctl --status 2>/dev/null | grep -qi "disabled"; then
  echo "  ⚠ Gatekeeper is disabled (spctl --status) — re-enable with 'sudo spctl --master-enable' to make this check meaningful"
  exit 0
fi

classify() {  # classify <app> — short reason an app failed spctl --assess
  local cs
  cs=$(codesign -dv "$1" 2>&1)
  if   echo "$cs" | grep -q "code object is not signed"; then
    echo "not signed"
  elif echo "$cs" | grep -qE 'flags=0x[0-9a-f]+\(.*adhoc'; then
    echo "ad-hoc signed (not Apple-notarized)"
  elif echo "$cs" | grep -q '^Authority=Developer ID Application'; then
    echo "Developer ID signed but not notarized"
  elif echo "$cs" | grep -q '^Authority=Apple Development'; then
    echo "development cert (not for distribution)"
  else
    echo "rejected (run 'codesign -dvvv \"$1\"' for details)"
  fi
}

ok=0
total=0
issues=()

while IFS= read -r app; do
  [ -z "$app" ] && continue
  total=$((total + 1))
  if spctl --assess --type execute "$app" >/dev/null 2>&1; then
    ok=$((ok + 1))
  else
    issues+=("${app##*/} — $(classify "$app")")
  fi
done < <(find /Applications -maxdepth 2 -name '*.app' -type d -prune -print 2>/dev/null)

if [ "$total" -eq 0 ]; then
  echo "  (no .app bundles found in /Applications)"
elif [ "${#issues[@]}" -eq 0 ]; then
  printf "  ✓ %d / %d apps signed + notarized\n" "$ok" "$total"
else
  printf "  ⚠ %d / %d apps signed + notarized\n" "$ok" "$total"
  echo  "  unsigned or not-notarized:"
  for i in "${issues[@]}"; do
    printf "     - %s\n" "$i"
  done
fi
