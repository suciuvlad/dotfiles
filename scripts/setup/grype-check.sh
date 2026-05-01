#!/usr/bin/env bash
# CVE scan over installed Homebrew packages and macOS apps.
# Invoked from `make check`. Informational only — always exits 0.
#
# Scans:
#   - $(brew --prefix)/Cellar    formulae (CLI tools)
#   - /Applications              cask-bundled libs (Electron node_modules,
#                                Java jars, etc.)
#
# First run downloads grype's vuln DB (~500 MB) and may take 30-60s.
# Subsequent runs hit the local cache and complete in a few seconds.
set -uo pipefail

command -v grype >/dev/null 2>&1 || { echo "  ⚠ grype not on PATH"; exit 0; }
command -v jq    >/dev/null 2>&1 || { echo "  ⚠ jq not on PATH (run 'make brew')"; exit 0; }

PREFIX="$(brew --prefix 2>/dev/null || echo /opt/homebrew)"
TARGETS=()
[ -d "$PREFIX/Cellar"  ] && TARGETS+=("dir:$PREFIX/Cellar")
[ -d "/Applications"   ] && TARGETS+=("dir:/Applications")

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "  ⚠ no scan targets found"
  exit 0
fi

scan_one() {  # scan_one <target>
  local target="$1" json
  if ! json=$(grype "$target" -o json --quiet 2>/dev/null); then
    printf "  ✗ %s — grype failed (run '%s %s' for details)\n" "$target" "grype" "$target"
    return
  fi

  local total
  total=$(printf '%s' "$json" | jq '.matches | length')
  if [ "$total" = "0" ]; then
    printf "  ✓ %s — no known CVEs\n" "$target"
    return
  fi

  printf "  ⚠ %s — %s findings:\n" "$target" "$total"
  printf '%s' "$json" \
    | jq -r '.matches | group_by(.vulnerability.severity)
             | map({sev: .[0].vulnerability.severity, n: length})
             | sort_by({Critical:0,High:1,Medium:2,Low:3,Negligible:4,Unknown:5}[.sev] // 9)
             | .[] | "       \(.sev): \(.n)"'
  printf "       (run 'grype %s' for the full list)\n" "$target"
}

for t in "${TARGETS[@]}"; do
  scan_one "$t"
done
