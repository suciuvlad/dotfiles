# Working on this repo

Personal dotfiles. GNU Stow layout: every top-level directory is a package
whose contents mirror `$HOME`. Read `README.md` for the human manual; this
file is what you need to not break things.

## Stow rules

- After adding/removing any file inside a package: `stow -R -t ~ <package>`.
- `~/Library/LaunchAgents` must stay a **real directory** — launchd won't
  scan a symlinked one at login. Never let stow fold it (bootstrap.sh
  pre-creates it; `make -C scripts agents` heals a folded one). If you add a
  similar `~/Library` path, apply the same treatment.
- `claude/.claude/` is deny-by-default in `.gitignore` with per-file `!`
  whitelists. Adding a tracked file there requires a matching `!` rule, or
  it will silently never commit. Runtime state (plugin caches, sessions,
  `settings.local.json`) stays ignored — `settings.json` is the portable
  plugin manifest; Claude Code reinstalls plugins from it on first launch.

## Setup steps (scripts/)

Probes are truth, the ledger is a journal: `make status` verifies every
step against the live machine and only uses recorded runs for timestamps.
A new setup step is not done until it exists in all five places:

1. `scripts/setup/<step>.sh` — sources `_lib.sh`, calls `emit_result`
2. `run_step` entry in `scripts/install.sh`
3. Target in `scripts/Makefile` (+ `.PHONY` + `make help` line)
4. `STEPS`/`LABELS`/`TARGETS` arrays in `scripts/setup/status.sh`
5. A live probe in `status.sh` — a probeless step degrades to "unknown"

Probe caveat: the weekly drift LaunchAgent runs probes with a bare PATH
(no `~/.local/bin`, no mise shims) — use absolute-path fallbacks for
anything not in `/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin`.

## defaults.sh

macOS settings go through `dw <domain> <key> <type> <value>` lines only.
The same lines drive apply and `--verify` — that symmetry is the probe
coverage. Don't write raw `defaults write` calls; `-dict-add` entries are
allowed but count as unverifiable.

## Verify before committing

```sh
make -C scripts lint   # shellcheck; CI's ubuntu shellcheck is STRICTER
make -C scripts test   # 20 probe/verify tests against fake $HOMEs, ~12s
```

CI runs both plus Brewfile validation on every push to master. The other
machines pull master blindly — don't push red.

## Package conventions

- Brew packages: strict essentials → `scripts/Brewfile`; anything
  best-effort (casks, niche tools) → `scripts/Brewfile.optional` (a picker
  menu, not a spec — its probe counts, never fails).
- CLI tools that npm would own go through mise (`mise/.tool-versions`,
  e.g. `npm:@openai/codex`) so they survive node bumps.
- AI-agent skills live in `agents/.agents/skills/` (the store); other
  tools symlink into it (`claude/.claude/skills/`, `agent-skills.sh` for
  cursor/codex). Don't vendor copies of things a plugin already provides.
