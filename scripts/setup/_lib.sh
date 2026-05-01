# Shared helpers for setup scripts. Source from any setup script that wants
# to participate in install.sh's structured summary. No-op when
# INSTALL_RESULT_FILE is unset, so each script still works standalone.
#
# Not directly executable; meant to be sourced.
# shellcheck shell=bash

# emit_result <step> <status> [detail] [failure1 failure2 ...]
#   step      machine id, e.g. "ssh", "brew-optional"
#   status    "ok" | "warn" | "fail"
#   detail    human-readable summary, e.g. "65/68 (3 failed)"
#   failures  optional list of per-item failure strings (one JSON entry each)
emit_result() {
  [ -z "${INSTALL_RESULT_FILE:-}" ] && return 0
  local step="$1" status="${2:-ok}" detail="${3:-}"
  shift 3 2>/dev/null || shift $#

  json_escape() { local s="${1//\\/\\\\}"; printf '%s' "${s//\"/\\\"}"; }

  local failures="[" first=1
  for f in "$@"; do
    [ "$first" -eq 0 ] && failures+=","
    failures+="\"$(json_escape "$f")\""
    first=0
  done
  failures+="]"

  printf '{"step":"%s","status":"%s","detail":"%s","failures":%s,"ts":%d}\n' \
    "$(json_escape "$step")" \
    "$(json_escape "$status")" \
    "$(json_escape "$detail")" \
    "$failures" \
    "$(date +%s)" \
    >> "$INSTALL_RESULT_FILE"
}
