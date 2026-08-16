# herdr layout helpers — the tmux/.tmux-functions.zsh trio (tdl/tdlm/tsl),
# ported to the herdr CLI. Both multiplexers stay usable; nothing here touches tmux.
#
# Vocabulary: herdr workspace ≈ tmux session, tab ≈ window, pane ≈ pane.
# `herdr pane run` types into the pane's interactive login zsh, so your aliases
# (c, cc, k, kk…) expand exactly like `tmux send-keys` did — and because the
# claude/codex/cursor/kimi integrations are installed, herdr still reports real
# agent state no matter how the agent was launched.
#
# Safety note: a herdr CLI target that is empty or omitted falls back to the
# UI-focused pane, which may belong to you or another client — so every call
# below passes an explicit pane id and bails rather than guessing.

# Guard: every helper needs to be running inside a herdr-managed pane.
_herdr_guard() {
  [[ ${HERDR_ENV:-} == 1 ]] && return 0
  echo "You must be inside herdr to use ${1}." >&2
  return 1
}

# Split <pane> in <direction>, print the new pane id.
# --ratio is the *existing* pane's share, the inverse of tmux's -p N.
# --no-focus everywhere keeps focus in the calling pane (tdl's closing select-pane).
_herdr_split() {
  local id
  id=$(herdr pane split "$1" --direction "$2" --ratio "$3" --cwd "$4" --no-focus \
    | jq -r '.result.pane.pane_id // empty')
  [[ -n $id ]] || { echo "herdr: failed to split $1" >&2; return 1; }
  print -r -- "$id"
}

# Run <command> in <pane>, refusing to fall back to whatever pane is focused.
_herdr_run() {
  [[ -n $1 ]] || { echo "herdr: refusing to run '$2' without a pane id" >&2; return 1; }
  herdr pane run "$1" "$2" >/dev/null
}

# Echo a split ratio as a float. Usage: _herdr_ratio <numerator> <denominator>
_herdr_ratio() {
  awk -v a="$1" -v b="$2" 'BEGIN { printf "%.4f", a / b }'
}

# Dev layout: editor left, AI right (30%), terminal bottom (15%).
# Usage: hdl <c|cc|k|codex|other_ai> [<second_ai>]
hdl() {
  [[ -z $1 ]] && { echo "Usage: hdl <c|cc|k|codex|other_ai> [<second_ai>]"; return 1; }
  _herdr_guard hdl || return 1

  local dir="${PWD}"
  local ai="$1" ai2="$2"
  local editor_pane="$HERDR_PANE_ID"
  local ai_pane ai2_pane

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$dir")" >/dev/null

  # Bottom terminal first, while the editor pane still spans the full width.
  _herdr_split "$editor_pane" down 0.85 "$dir" >/dev/null || return 1
  # Then carve the AI column out of the editor pane.
  ai_pane=$(_herdr_split "$editor_pane" right 0.7 "$dir") || return 1

  if [[ -n $ai2 ]]; then
    ai2_pane=$(_herdr_split "$ai_pane" down 0.5 "$dir") || return 1
    _herdr_run "$ai2_pane" "$ai2"
  fi

  _herdr_run "$ai_pane" "$ai"
  _herdr_run "$editor_pane" "$EDITOR ."
}

# One hdl tab per subdirectory of $PWD, workspace renamed after the parent.
# (Alternative worth trying: a workspace per repo instead of a tab — the sidebar
#  groups agents by space. Swap `tab create` for `workspace create` to get that.)
# Usage: hdlm <c|cc|k|codex|other_ai> [<second_ai>]
hdlm() {
  [[ -z $1 ]] && { echo "Usage: hdlm <c|cc|k|codex|other_ai> [<second_ai>]"; return 1; }
  _herdr_guard hdlm || return 1

  local ai="$1" ai2="$2"
  local base_dir="${PWD}"
  local first=true
  local dir dirpath pane_id hdl_command

  herdr workspace rename "$HERDR_WORKSPACE_ID" "$(basename "$base_dir")" >/dev/null

  # (N) so a directory with no subdirectories doesn't abort on zsh's NOMATCH —
  # the workspace has already been renamed by this point.
  for dir in "$base_dir"/*/(N); do
    [[ -d $dir ]] || continue
    dirpath="${dir%/}"

    # ${(q)…} quotes properly: an AI command containing a space would otherwise
    # word-split and be read as "second AI", silently adding a fourth pane.
    hdl_command="hdl ${(q)ai}"
    [[ -n $ai2 ]] && hdl_command="$hdl_command ${(q)ai2}"

    if $first; then
      # Reuse the calling pane for the first project.
      _herdr_run "$HERDR_PANE_ID" "cd ${(q)dirpath} && $hdl_command"
      first=false
    else
      pane_id=$(herdr tab create --workspace "$HERDR_WORKSPACE_ID" --cwd "$dirpath" \
        --label "$(basename "$dirpath")" --no-focus | jq -r '.result.root_pane.pane_id // empty')
      _herdr_run "$pane_id" "$hdl_command"
    fi
  done
}

# Swarm layout: <count> tiled panes all running <command>.
# herdr has no `select-layout tiled`, so the grid is computed: ceil(sqrt(count))
# columns, rows spread across them, each split taking 1/(remaining) so the result
# is exactly even. Deterministic and in reading order — and it never has to ask
# herdr which pane is "current", which is the call that can target someone else's.
# Usage: hsl <pane_count> <command>
hsl() {
  [[ -z $1 || -z $2 ]] && { echo "Usage: hsl <pane_count> <command>"; return 1; }
  _herdr_guard hsl || return 1

  local count="$1" cmd="$2"
  local dir="${PWD}"
  local -a columns panes
  local cols=1 k index col rows j last pane

  herdr tab rename "$HERDR_TAB_ID" "$(basename "$dir")" >/dev/null

  while (( cols * cols < count )); do ((cols++)); done

  # Peel each new column off the rightmost one, keeping the array left-to-right.
  columns=("$HERDR_PANE_ID")
  for (( k = 1; k < cols; k++ )); do
    columns+=("$(_herdr_split "${columns[-1]}" right "$(_herdr_ratio 1 $((cols - k + 1)))" "$dir")") || return 1
  done

  # Split each column into its share of rows (zsh arrays are 1-indexed, so the
  # remainder check is <=, not < as it would be in bash).
  for (( index = 1; index <= cols; index++ )); do
    col="${columns[index]}"
    rows=$(( count / cols ))
    (( index <= count % cols )) && (( rows++ ))
    panes+=("$col")
    last="$col"
    for (( j = 1; j < rows; j++ )); do
      last=$(_herdr_split "$last" down "$(_herdr_ratio 1 $((rows - j + 1)))" "$dir") || return 1
      panes+=("$last")
    done
  done

  for pane in "${panes[@]}"; do
    _herdr_run "$pane" "$cmd"
  done
}
