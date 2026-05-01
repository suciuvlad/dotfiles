# Other packages

CLI tools from [`scripts/Brewfile.optional`](../scripts/Brewfile.optional) that aren't shell utilities or language runtimes — security scanners, cloud SDKs, media tools, alternates.

---

## Security

### `nmap`
Network port scanner.
- `nmap <host>` — quick scan
- `nmap -sV -p- <host>` — full port range with version detection
- `nmap -A <host>` — aggressive (OS detection, scripts, traceroute)

**Upstream:** <https://nmap.org>

### `nuclei`
YAML-template-based vulnerability scanner.
- `nuclei -u https://example.com` — run all templates
- `nuclei -u <target> -t cves/` — only CVE templates
- `nuclei -update-templates`

**Upstream:** <https://github.com/projectdiscovery/nuclei>

### `nikto`
Web-server vulnerability scanner.
- `nikto -h https://example.com`

**Upstream:** <https://github.com/sullo/nikto>

### `testssl`
TLS/SSL configuration auditor.
- `testssl example.com` — full audit
- `testssl -p example.com` — protocols only

**Upstream:** <https://testssl.sh>

### `grype`
Vulnerability scanner for container images and filesystems.
- `grype <image>:<tag>` — scan an image
- `grype dir:.` — scan a directory
- `grype sbom:./sbom.json` — scan an SBOM

**Upstream:** <https://github.com/anchore/grype>

### `mkcert`
Locally-trusted dev certificates without the OpenSSL ceremony.
- `mkcert -install` — install local CA into the system + browser trust stores
- `mkcert example.local` — issue a cert for example.local

**Upstream:** <https://github.com/FiloSottile/mkcert>

---

## Cloud / data

(See [Dev stacks › Cloud SDKs](05-dev-stacks.md#cloud-sdks) for `awscli`, `gcloud-cli`, `cloudflared`, `ansible`.)

### `supabase`
See [Dev stacks › Databases](05-dev-stacks.md#supabasetapsupabase-brewfileoptional).

---

## Media

### `ffmpeg`
The universal media converter. Cuts video, transcodes audio, extracts frames, generates GIFs.
- `ffmpeg -i in.mov -c:v libx264 -crf 18 out.mp4` — re-encode to H.264
- `ffmpeg -i in.mp4 -ss 00:00:10 -t 5 out.gif` — 5s GIF from 10s mark
- `ffmpeg -i in.mp3 -ar 44100 -ac 1 out.wav` — mono 44.1kHz WAV
- `ffmpeg -i in.mp4 -an out.mp4` — strip audio

**Upstream:** <https://ffmpeg.org>

---

## Alternate multiplexers

### `zellij`
Terminal multiplexer with discoverable keybindings (status bar shows them). An alternative to tmux when you want a friendlier learning curve.
- `zellij` — start
- `zellij --layout dev` — start with a layout
- `Ctrl-p n` — new pane (default keybindings)

This repo uses tmux as the primary multiplexer (full config in `tmux/`). `zellij` is here for experimentation.

**Upstream:** <https://zellij.dev>

---

## Linters / formatters

### `hadolint`
Dockerfile linter.
- `hadolint Dockerfile`
- `hadolint --ignore DL3008 Dockerfile`

**Upstream:** <https://github.com/hadolint/hadolint>

### `markdownlint-cli`
Markdown linter.
- `markdownlint '**/*.md'`
- `markdownlint -f file.md` — auto-fix where possible

**Upstream:** <https://github.com/igorshubovych/markdownlint-cli>

### `sqlfluff`
SQL linter + formatter (multi-dialect).
- `sqlfluff lint --dialect postgres queries.sql`
- `sqlfluff fix --dialect postgres queries.sql`

**Upstream:** <https://sqlfluff.com>

---

## Niche

### `tldr`
Already covered in [Shell tools](03-shell-tools.md#tldr) — listed here for completeness if browsing the Brewfile.
