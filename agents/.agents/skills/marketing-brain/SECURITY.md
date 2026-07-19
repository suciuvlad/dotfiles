# security policy

read first. report second. fix third.

## supported versions

| version | security fixes |
|---------|----------------|
| 0.1.x   | yes (current)  |

## reporting a vulnerability

email **`223140489+AgriciDaniel@users.noreply.github.com`** with subject `marketing-brain security:` and a brief description. for higher-impact findings, open a [private security advisory](https://github.com/AgriciDaniel/marketing-brain/security/advisories/new) on github.

include:

- what you found
- the file path + line numbers
- a minimal reproducer (or the smallest viable description)
- your assessment of impact

i'll acknowledge inside 72 hours and aim to ship a fix or document a workaround inside two weeks. for time-sensitive issues (active exploitation, credential exposure, supply-chain compromise) say so in the subject and i'll move faster.

## scope

| in scope | out of scope |
|----------|--------------|
| pipeline scripts (`scripts/*.py`) | upstream dependencies (report to openpyxl / weasyprint upstream) |
| vault renderer + scaffolded template behaviour | dataforseo api itself (report to dataforseo) |
| credential handling, command/path injection, ssrf, prompt injection in beast-planner bundle | obsidian plugin behaviour |
| infrastructure-as-code (none currently shipped) | issues that require root-equivalent access on the operator's own machine |

## what's already hardened (v0.1.1)

Internal audit notes are intentionally not shipped with the repository.
The v0.1.0 -> v0.1.1 public disposition is: 16 of 22 findings closed
across 6 bounded slices. headlines:

- per-vault `flock` + atomic state writes; refuse-on-corruption
- `MARKETING_BRAIN_MAX_BUDGET` env ceiling clamps user-supplied cost caps; persistent spend ledger across runs
- `--site` scheme allow-list + loopback/private-ip block (ssrf)
- pdf placeholder html-escape with explicit allowlist; `--base-url about:blank` on weasyprint invocation
- beast-planner subagent's tool surface restricted to `read + write + glob + grep` (no bash); competitor / paa data wrapped in `<untrusted-external-data>` fences inside the synthesis bundle
- credential redaction in 4xx error bodies; 429 honours `Retry-After`

## credential handling — operator responsibilities

- **never** commit `DATAFORSEO_LOGIN` / `DATAFORSEO_PASSWORD` to any file. the skill reads them from environment variables only. `.gitignore` excludes `.env`, `.env.*`, `*.env`, `secrets/`, `credentials.json`.
- if you ever paste a credential into chat (even "temporarily"), rotate it after the session.
- the skill's redaction pass scrubs `Authorization: Basic <...>` and base64-shaped tokens from any error body before logging — but the safest credential is the one that never enters a process you don't fully trust.

## thanks

thanks for taking the time to look. a clear report is worth far more than a noisy one.
