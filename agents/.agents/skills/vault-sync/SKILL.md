---
name: vault-sync
description: Ingest finished marketing artifacts (audits, strategy docs, research files) from any working folder into a marketing-brain vault following the CODEX convention — immutable raw copy, source note, manifest registration, graph wiring, fold into wiki notes, lint. Use when the user says "vault-sync", "ingest into the vault", "sync to marketing brain", "check this into the brain", or names a report/audit/strategy file they want preserved in a marketing-brain vault.
---

# vault-sync — check a finished artifact into a marketing-brain vault

marketing-brain has **no ingest command**; documents enter a vault only through the
CODEX source convention. This skill performs that convention deterministically.
It **copies** files — never moves or edits the originals.

## Invocation

```
/vault-sync <file> [<file>…] [--vault <slug-or-path>] [--provider <name>]
```

- **files** — one or more paths (absolute or relative to cwd). Markdown, JSON,
  XML, CSV, XLSX all fine. Directories are not accepted; list the files inside.
- **--vault** — a slug resolved against `~/marketing-brain-vaults/<slug>` or an
  absolute path. Default: `wild-io`. If the resolved directory does not contain
  `.raw/.manifest.json`, STOP and list the directories in
  `~/marketing-brain-vaults/` so the user can pick.
- **--provider** — subfolder under `.raw/sources/` grouping the evidence by
  origin. Default: `academy` when cwd is under `~/dev/wild-academy`, otherwise
  `manual`. Existing provider folders (`dataforseo/`, `ahrefs/`, `google/`,
  `site/`, `visuals/`, `academy/`) are ad-hoc names, not an enum — reuse one
  when it fits, coin one when it doesn't.

Let `VAULT` = resolved vault path, `TODAY` = today's date `YYYY-MM-DD`.

## Hard rules (from the vault's CODEX)

1. **Raw files are immutable.** Never edit anything under `.raw/`. A refreshed
   document gets a NEW dated copy and a NEW manifest entry; the old one stays.
2. **No loose files.** Nothing is ever placed at the vault root or dropped into
   `wiki/` without full frontmatter + an inbound wikilink (lint errors otherwise).
3. **Every wiki note needs frontmatter** with at least
   `brain_schema, type, title, created, updated, status`.
4. **Evidence chain**: raw copy ⟶ hash in manifest ⟶ hash in source note ⟶
   wiki notes cite the source note by wikilink. Numbers quoted in wiki notes must
   trace to a filed source.

## Procedure — per file

### 0. Duplicate check
Compute `HASH=$(shasum -a 256 <file> | cut -d' ' -f1)`. Grep
`$VAULT/.raw/.manifest.json` for that hash. If present, report which manifest id
already holds it and SKIP the file (identical content re-ingest is a no-op).
Same *name* but different hash is a refresh: proceed, using today's date in the
filename — do not touch the earlier copy.

### 1. Immutable raw copy
```
mkdir -p "$VAULT/.raw/sources/<provider>"
cp <file> "$VAULT/.raw/sources/<provider>/<kebab-name>-$TODAY.<ext>"
chmod 600 <that copy>
```
`<kebab-name>` = source filename, lowercased, kebab-cased, extension preserved.
Verify the copy's SHA-256 equals `HASH`.

### 2. Source note — `wiki/sources/<Title>.md`
`<Title>` = short human title in Title Case (e.g. "Academy Blog Audit 2026-07").
If a note for an earlier version of the same document exists, UPDATE that note
(append a dated section, bump `updated`/`source_manifest_id`/`source_hash`)
instead of creating a near-duplicate stem — lint rejects duplicate stems.

Template (fill every field; copy `owner` and `business_type` from an existing
source note in the same vault):

```markdown
---
brain_schema: marketing-brain.v1
owner: <vault owner email>
confidence: <low|medium|high — how much you trust the doc's claims>
approval_status: needs-review
rollback_note: Raw copy is immutable; refresh by adding a new dated copy under .raw/sources/<provider>/.
risk_level: <low|medium|high>
business_type: <from vault>
source_manifest_id: <manifest key from step 3>
source_hash: <HASH>
retrieved_at: <TODAY>
last_verified: <TODAY>
type: source
title: <Title>
created: <TODAY>
updated: <TODAY>
tags:
  - source
  - <provider>
  - <2-3 topical tags>
status: developing
related:
  - "[[<client entity>]]"
  - "[[<each wiki note this evidence feeds>]]"
sources:
  - <original path> (provided by <who> <TODAY>)
---

# <Title>

**Status: filed <TODAY>.** <One line: what the doc is, who/what produced it.>
Copied to `.raw/sources/<provider>/<kebab-name>-<TODAY>.<ext>` (<size>, 0600,
immutable). SHA-256: `<first-8>…<last-6>` (full hash in frontmatter and
`.raw/.manifest.json`).

## Contents

<5–15 lines: the key findings/numbers/structure. Concrete figures, not vibes.>

## How to use this source

<2–5 bullets: which wiki notes should draw on it, what analysis it unlocks,
refresh rule.>
```

### 3. Manifest entry — `$VAULT/.raw/.manifest.json`
Add under `sources` (key: `<provider>-<kebab-name>-$TODAY`), and set the
top-level `last_updated` to `TODAY`:

```json
"<provider>-<kebab-name>-<TODAY>": {
  "hash": "<HASH>",
  "ingested_at": "<TODAY>",
  "notes": "<one-line summary with the headline number>",
  "pages_created": ["wiki/sources/<Title>.md", "<any new wiki notes from step 5>"],
  "pages_updated": ["wiki/index.md", "wiki/log.md", "wiki/hot.md", "<any updated notes>"],
  "path": ".raw/sources/<provider>/<kebab-name>-<TODAY>.<ext>",
  "provider": "<provider> (<origin, e.g. 'wild-academy repo, owner-provided'>)"
}
```

### 4. Graph wiring (batch these once per run, not per file)
- **`wiki/index.md`** — add `[[<Title>]]` (with a short em-dash annotation) under
  `## Sources`. Required: an unlinked note is an orphan-lint ERROR. Bump `updated`.
- **`wiki/log.md`** — append one dated entry for the whole batch: files ingested,
  manifest ids, wiki notes created/updated.
- **`wiki/hot.md`** — refresh working memory: what new intel is now in the vault
  and what it changes. Bump `updated`.

### 5. Fold findings into synthesis-visible notes — DO NOT SKIP
`synthesize_beast_plan.py` and the beast-planner agent read only the structured
`wiki/audits/`, `wiki/keywords/`, `wiki/entities/`, `wiki/decisions/` notes —
never loose sources. A source note alone is archived but strategically inert.

For each ingested doc, decide where its findings live:
- matches an existing note's topic → **append** a dated section at the bottom
  citing `[[<Title>]]` (never rewrite existing content — operator edits are
  preserved by convention)
- new topic → **create** the note (full frontmatter, `type: audit` /
  `type: keywords` / etc. matching siblings in that folder), link it from
  `wiki/index.md` under the right heading, cite `[[<Title>]]` for every number
- purely reference data (datasets, briefs) → the source note's "How to use"
  section may be enough; say so explicitly in the run report

### 6. Lint + report
```
python3 ~/.claude/skills/marketing-brain/scripts/lint_vault.py --vault "$VAULT"
```
(`marketing-brain lint --vault "$VAULT"` if the CLI is on PATH.) Fix any
failures you introduced. Then report: per-file table (raw path, manifest id,
source note, hash prefix, skipped-as-duplicate), wiki notes created/updated,
lint result. Remind the user the originals were not moved.
