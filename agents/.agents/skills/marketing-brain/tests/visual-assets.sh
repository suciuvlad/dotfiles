#!/usr/bin/env bash
# Repository share-readiness checks for Marketing Brain visual and legal assets.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
FAILED_TESTS=()

log_pass() { PASS=$((PASS + 1)); echo "  ok  $1"; }
log_fail() { FAIL=$((FAIL + 1)); FAILED_TESTS+=("$1"); echo "  bad $1"; }

assert_file_exists() {
  local path="$1"
  if [[ -f "$ROOT/$path" ]]; then log_pass "exists: $path"; else log_fail "missing: $path"; fi
}

assert_path_absent() {
  local path="$1"
  if [[ ! -e "$ROOT/$path" ]]; then log_pass "absent: $path"; else log_fail "should be absent: $path"; fi
}

assert_contains() {
  local path="$1" pattern="$2"
  if grep -qE "$pattern" "$ROOT/$path"; then log_pass "$path contains $pattern"; else log_fail "$path missing $pattern"; fi
}

assert_not_contains() {
  local path="$1" pattern="$2"
  if grep -qE "$pattern" "$ROOT/$path"; then log_fail "$path should not contain $pattern"; else log_pass "$path excludes $pattern"; fi
}

assert_size_under_kb() {
  local path="$1" max_kb="$2"
  local size_kb
  size_kb="$(du -k "$ROOT/$path" | cut -f1)"
  if [[ "$size_kb" -le "$max_kb" ]]; then
    log_pass "$path ${size_kb}KB <= ${max_kb}KB"
  else
    log_fail "$path ${size_kb}KB > ${max_kb}KB"
  fi
}

assert_svg_valid() {
  local path="$1"
  if python3 -c "import xml.etree.ElementTree as ET; ET.parse('$ROOT/$path')" 2>/dev/null; then
    log_pass "xml valid: $path"
  else
    log_fail "xml invalid: $path"
  fi
}

assert_svg_accessible() {
  local path="$1"
  if grep -q "<title" "$ROOT/$path" && grep -q "<desc" "$ROOT/$path" && grep -q 'role="img"' "$ROOT/$path"; then
    log_pass "accessible svg metadata: $path"
  else
    log_fail "missing svg accessibility metadata: $path"
  fi
}

assert_readme_order() {
  local first="$1" second="$2"
  python3 - "$ROOT/README.md" "$first" "$second" <<'PY'
import sys
text = open(sys.argv[1], encoding="utf-8").read()
first = text.find(sys.argv[2])
second = text.find(sys.argv[3])
raise SystemExit(0 if first != -1 and second != -1 and first < second else 1)
PY
  if [[ "$?" -eq 0 ]]; then
    log_pass "README order: $first before $second"
  else
    log_fail "README order: $first before $second"
  fi
}

main() {
  local svgs=(
    "assets/svg/hero-frontispiece-a2.svg"
    "assets/svg/pipeline-six-step-d1.svg"
    "assets/svg/flow-framework-e1.svg"
    "assets/svg/vault-output-map-e1.svg"
    "assets/svg/release-build-v011-e1.svg"
  )

  echo "[visual assets]"
  for svg in "${svgs[@]}"; do
    assert_file_exists "$svg"
    assert_svg_valid "$svg"
    assert_svg_accessible "$svg"
  done

  assert_file_exists "assets/webp/marketing-brain_01.webp"
  assert_file_exists "assets/webp/marketing-brain_03.webp"
  assert_size_under_kb "assets/webp/marketing-brain_01.webp" 600
  assert_size_under_kb "assets/webp/marketing-brain_03.webp" 1600
  assert_readme_order "marketing-brain_03.webp" "marketing-brain_01.webp"

  echo "[removed orphan visuals]"
  assert_path_absent "assets/svg/v0-1-1-shipped.svg"
  assert_path_absent "assets/svg/per-change-loop-applied.svg"
  assert_path_absent "assets/svg/audit-funnel.svg"
  assert_path_absent "assets/svg/audit-disposition-v011-e1.svg"
  assert_path_absent "docs/superpowers"
  assert_path_absent "marketing-brain-video-images/Pasted Image.png"

  echo "[license surface]"
  assert_contains "LICENSE" "Marketing Brain Proprietary License"
  assert_contains "README.md" "source-available proprietary software"
  assert_contains ".claude-plugin/plugin.json" '"license": "Proprietary"'
  assert_contains "SKILL.md" '^license: Proprietary$'
  assert_not_contains "README.md" "License: MIT|Pull requests welcome|SECURITY-AUDIT.md"

  echo
  echo "Result: $PASS passed, $FAIL failed."
  if [[ "$FAIL" -gt 0 ]]; then
    printf '  - %s\n' "${FAILED_TESTS[@]}"
    exit 1
  fi
}

main "$@"
