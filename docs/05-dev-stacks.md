# Dev stacks

Language toolchains and DBs. All language runtimes are managed by [`mise`](03-shell-tools.md#mise) — global versions live in [`mise/.tool-versions`](../mise/.tool-versions); per-project versions live in a project-local `.tool-versions` (or `.mise.toml`).

```
# mise/.tool-versions (global defaults)
node lts
go latest
python 3.13
ruby latest
```

`mise install` (or `make runtimes`) installs all of them.

---

## Node / JavaScript

### Runtime
- `node` — managed by `mise`. Global default is `lts`. Pin per-project with `mise use node@22`.
- `bun` (Brewfile.optional, `oven-sh/bun` tap) — alt JS runtime + bundler + package manager. `BUN_INSTALL=$HOME/.bun` (`zsh/.zshrc:7,14`) keeps `bun add -g` binaries on PATH; completions via `$BUN_INSTALL/_bun`.

### Package managers
- `pnpm` (Brewfile, strict) — preferred for monorepos / disk-efficient installs. `PNPM_HOME=~/Library/pnpm` on PATH.
- `yarn` (Brewfile, strict) — for projects that mandate it.
- `npm` — bundled with node.

### Starting a new project
```sh
mkdir myapp && cd myapp
mise use node@lts                 # writes .tool-versions
pnpm init
pnpm add -D typescript prettier
```

### Linting / formatting
- ESLint config: `shell/.eslintrc` (stowed to `~/.eslintrc`)
- Prettier: invoked via [`conform.nvim`](04-tuis.md#neovim) on save in nvim
- `markdownlint-cli` (Brewfile.optional) for markdown

---

## Go

### Runtime
- `go` — managed by `mise`. Global default is `latest`.
- `GOPATH=$HOME/go` (`zsh/.zshrc:4`); `$GOPATH/bin` on PATH for `go install`-ed binaries.
- `GOPRIVATE=github.com/purposeinplay/*` (`zsh/.zshrc:3`) — bypass the proxy/sumdb for that org's private modules.

### Tooling (Brewfile.optional)
| Tool                | Why                                                                  |
|---------------------|----------------------------------------------------------------------|
| `buf`               | Protobuf linter + breaking-change checker + codegen front-end        |
| `delve`             | Go debugger; backs `nvim-dap-go`                                     |
| `golangci-lint`     | Aggregator for staticcheck, govet, errcheck, etc.                    |
| `grpcurl`           | `curl` for gRPC services                                             |
| `protobuf`          | `protoc` compiler                                                    |

### LSP / nvim integration
- `gopls` (installed by Mason) — LSP. Configured in `nvim/.config/nvim/lua/plugins/lsp-config.lua` with `unusedparams`, `shadow`, `staticcheck`, postfix completions.
- `nvim-dap-go` — debugger config presets.
- `goimports` + `gofmt` — autoformat on save (`conform.nvim`).

### Workflow
```sh
mkdir mysvc && cd mysvc
go mod init github.com/me/mysvc
mise use go@latest
go install golang.org/x/tools/cmd/goimports@latest
```

---

## Python

### Runtime
- `python` 3.13 — managed by `mise`.
- `uv` (Brewfile.optional) — modern Python package + project manager. Replaces pip/pipenv/poetry/virtualenv for most use cases.

### Workflow with `uv`
```sh
uv init myapp && cd myapp        # scaffold pyproject.toml
uv add requests                  # add dep, lock, install
uv run python script.py          # run inside the project venv
uv tool install ruff             # install a CLI tool globally
uv tool run black file.py        # one-shot run a tool (uvx)
uv pip compile requirements.in   # pip-tools-style compile
```

`uv` reads `pyproject.toml` + `uv.lock`. No `python -m venv` needed; `uv run` handles activation transparently.

---

## Ruby

### Runtime
- `ruby` — managed by `mise`. Global default is `latest`.
- The `r` zsh alias maps to `rails` for Rails projects.

### Workflow
```sh
mise use ruby@latest
gem install bundler
bundle init
bundle add rails
```

---

## Rust

### Toolchain
- `rust` (Brewfile.optional) — installs `rustup`, which manages `cargo`, `rustc`, `clippy`, `rustfmt`. (Not via `mise` — `rustup` is the canonical Rust installer.)

### Workflow
```sh
rustup default stable
cargo new myapp
cargo build && cargo test
cargo clippy -- -D warnings
```

---

## Databases

### `postgresql@17` (Brewfile, strict)
Full server + client. Run as a brew service when needed:

```sh
brew services start postgresql@17       # background daemon
brew services stop  postgresql@17
psql postgres                           # connect
createdb myapp_dev
psql myapp_dev < seed.sql
```

For production-ish work, prefer Docker (`lazydocker` to manage). For quick local dev, the brew service is faster.

### `supabase/tap/supabase` (Brewfile.optional)
Supabase CLI. Local stack on Docker:

```sh
supabase init                           # scaffolds supabase/ in project
supabase start                          # spins up postgres + studio + auth + storage in Docker
supabase status                         # show URLs (incl. studio at :54323)
supabase db reset                       # rebuild from migrations + seed
supabase migration new <name>
supabase functions deploy <name>
```

---

## Container / orchestration

- `docker-desktop` (Brewfile.optional cask) — Docker engine + GUI.
- `lazydocker` — TUI front-end (see [TUIs](04-tuis.md#lazydocker)).
- `d` zsh alias → `docker`.

---

## Cloud SDKs

### `awscli` (Brewfile.optional)
```sh
aws configure                           # set up credentials
aws s3 ls
aws sts get-caller-identity             # who am I
```

### `gcloud-cli` (Brewfile.optional cask)
```sh
gcloud auth login
gcloud config set project <proj>
gcloud projects list
```

`zsh/.zshrc:102-103` sources `path.zsh.inc` and `completion.zsh.inc` from `~/google-cloud-sdk/` if present.

### `cloudflared` (Brewfile.optional)
Cloudflare Tunnel client. Expose a local service publicly:
```sh
cloudflared tunnel --url http://localhost:3000
```

### `ansible` (Brewfile.optional)
Configuration management. Mostly for ad-hoc remote tasks:
```sh
ansible all -i hosts.ini -m ping
ansible-playbook site.yml -i hosts.ini
```
