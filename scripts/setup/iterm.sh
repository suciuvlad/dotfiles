#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=_lib.sh
. "$(dirname "$0")/_lib.sh"

curl -L https://iterm2.com/shell_integration/install_shell_integration.sh | bash
emit_result "iterm" "ok" "shell integration installed"
