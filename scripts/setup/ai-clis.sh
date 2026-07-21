#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

# AI coding CLIs that don't come from brew or mise's core runtimes:
#   claude — native installer into ~/.local (self-updating; the "claude"
#            brew cask is the desktop app, not this CLI)
#   kimi   — Moonshot installer into ~/.kimi-code/bin (PATH set in .zshrc)
# codex is mise-managed (npm:@openai/codex in ~/.tool-versions) so it
# survives node version bumps — installed by 'make runtimes', verified here.

installed=()
failed=()

if command -v claude >/dev/null 2>&1 || [ -x "$HOME/.local/bin/claude" ]; then
  echo "· claude already installed"
else
  echo "→ installing Claude Code (native installer)"
  if curl -fsSL https://claude.ai/install.sh | bash; then
    installed+=("claude")
  else
    failed+=("claude — installer failed")
  fi
fi

if [ -x "$HOME/.kimi-code/bin/kimi" ]; then
  echo "· kimi already installed"
else
  echo "→ installing Kimi CLI"
  if curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash; then
    installed+=("kimi")
  else
    failed+=("kimi — installer failed")
  fi
fi

if command -v codex >/dev/null 2>&1 || mise which codex >/dev/null 2>&1; then
  echo "· codex present (mise-managed via ~/.tool-versions)"
else
  failed+=("codex — mise-managed; run 'make runtimes'")
fi

if [ ${#failed[@]} -gt 0 ]; then
  printf '✗ %s\n' "${failed[@]}" >&2
  emit_result "ai-clis" "warn" "${#failed[@]} of 3 missing" "${failed[@]}"
  exit 1
fi

[ ${#installed[@]} -gt 0 ] && echo "✓ installed: ${installed[*]}"
echo "✓ AI CLIs present: claude, codex, kimi"
emit_result "ai-clis" "ok" "claude, codex, kimi"
