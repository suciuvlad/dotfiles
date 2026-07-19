---
brain_schema: marketing-brain.v1
type: source
title: "Beast Plan Synthesis Bundle"
created: 2026-05-11
updated: 2026-05-11
tags:
  - source/internal
  - beast-plan
status: developing
---

# Beast Plan Synthesis Bundle

Vault: `sample-vault`
Business type: `saas`

## Current Search Requirements

# Current Search Requirements Memo

Reviewed: 2026-05-11

Scope: Google Search, AI Overviews/AI Mode, Search Console measurement,
generative AI content guidance, spam policy risk, DataForSEO ranked keywords,
and Obsidian properties/Bases assumptions used by Marketing Brain v0.1.5.

## Release Positioning

Marketing Brain must not claim guaranteed rankings, guaranteed recovery,
guaranteed traffic, or guaranteed AI Overview inclusion. The correct claim is
that the brain improves evidence quality, source hygiene, technical readiness,
content planning, and execution governance.

## Google AI Features

Official source: https://developers.google.com/search/docs/appearance/ai-features?hl=en

Release-relevant requirements:

- Google states that standard SEO best practices remain relevant for AI
  Overviews and AI Mode.
- Pages need to be indexed and eligible to appear in Google Search with a
  snippet to be eligible as supporting links.
- Google says there are no additional AI-feature-specific technical
  requirements.
- Google says no special schema.org markup, AI text file, or machine-readable
  file is required for AI features.
- AI Overview and AI Mode traffic is included in overall Search Console Web
  performance data rather than exposed as a separate Marketing Brain KPI.

Marketing Brain implication: use AI/AIO language around eligibility, source
quality, query coverage, and measurement discipline. Do not present a separate
guaranteed AIO ranking workflow.

## Generative AI Content

Official source: https://developers.google.com/search/docs/fundamentals/using-gen-ai-content?hl=en

Release-relevant requirements:

- Generative AI can support research and structure.
- Scaled generated pages that do not add value can violate spam policies.
- Content should focus on accuracy, quality, relevance, and user value.
- Metadata, structured data, and alt text created with automation still need
  normal quality and policy compliance.

Marketing Brain implication: page briefs can use AI assistance, but the vault
must require real evidence, source review, owner approval, and quality checks
before publication.

## Spam Policy

Official source: https://developers.google.com/search/docs/essentials/spam-policies?hl=en

Release-relevant risks:

- Scaled content abuse, deceptive behavior, link schemes, and low-value
  automation are release-critical risks.
- The brain must reject link buying, PBNs, incentivized review wording, cloaked
  content, doorway pages, and mass AI pages without added value.

Marketing Brain implication: strategy notes must include risk, confidence,
owner, approval status, and rollback fields before implementation.

## DataForSEO Ranked Keywords

Official source: https://docs.dataforseo.com/v3/dataforseo_labs-google-ranked_keywords-live/

Release-relevant assumptions:

- The endpoint is `POST /v3/dataforseo_labs/google/ranked_keywords/live`.
- It returns keywords a domain or webpage ranks for, with SERP elements,
  monthly searches, and other keyword data.
- Data is updated weekly according to DataForSEO docs.
- Requests are paid and should remain behind hard cost caps and dry-run previews.

Marketing Brain implication: raw API responses remain immutable under `.raw/`,
source notes must cite the raw file, and release tests should include
deterministic fixtures so buyer demos do not require live paid calls.

## Obsidian Properties And Bases

Official sources:

- https://help.obsidian.md/properties
- https://help.obsidian.md/bases

Release-relevant assumptions:

- Obsidian properties are stored as YAML frontmatter at the top of Markdown
  notes.
- Properties should stay flat and machine-readable.
- Bases use local Markdown files and their properties as the data source.

Marketing Brain implication: `brain_schema`, source IDs, confidence, owner,
approval, risk, and freshness fields belong in flat YAML frontmatter. Bases
should read those fields rather than nested structures.

## Release Gate

This memo should be refreshed before every paid release. If official docs
change, update README, SKILL, report language, and vault notes before tagging.

## FLOW Framework

---
type: source
title: "FLOW Framework — canonical reference"
created: 2026-05-04
updated: 2026-05-04
tags:
  - framework
  - flow
  - reference
status: mature
related:
  - "[[beast-plan-prompt]]"
sources:
  - "https://github.com/AgriciDaniel/flow"
---

# FLOW Framework

> **Bundled with `marketing-brain` v0.1.5** — this is a snapshot of the canonical
> FLOW Framework page mirrored from `github.com/AgriciDaniel/flow` at skill
> release time. The upstream repo is the source of truth; if it changes, this
> file may lag. Re-sync periodically by copying `docs/01-framework/flow-framework.md`
> from the FLOW repo back into this path.
>
> © Daniel Agrici, CC BY 4.0 — github.com/AgriciDaniel/flow

---

## What This Is

FLOW is a search-and-conversion loop for 2026 discovery. It treats rankings, AI
citations, local visibility, and sales evidence as connected surfaces rather
than separate channels.

FLOW uses four plain stages: **Find** demand, **Leverage** distributed
evidence, **Optimize** owned assets for extraction and trust, and **Win** with
pages and measurements that connect discovery to revenue. This page applies
that loop to the framework layer.

## Why It Matters In 2026

Ahrefs found a 58% lower average CTR for position-one content when an AI
Overview was present in its December 2025 dataset.

seoClarity found that 25% of top cited ChatGPT URLs had no Google organic
visibility in its cited-page sample.

Search is no longer one result page and one click path. A useful SEO system has
to survive classic rankings, AI summaries, local packs, business profiles,
community references, and sales feedback. The practical goal is not to chase
every surface equally; it is to decide which surface can change the next
business outcome and then build evidence there.

## How To Apply

- Name the search surface before writing: organic result, AI answer, local
  pack, community discussion, paid landing page, or sales-assisted page.
- Separate observable evidence from assumptions. Claims with numbers must
  trace to the bibliography or be removed.
- Write from buyer language first, then add entity clarity, internal links,
  proof, and conversion next steps.
- Review the asset as an AI-readable document: clear headings, direct answers,
  concise tables where useful, source labels, and no hidden dependence on
  private examples.

## Operating Workflow

1. Define the business outcome before choosing tactics. A page meant to create
   a qualified call should not be judged only by impressions, and a profile
   meant to reconcile business facts should not be judged only by post
   frequency.
2. Inventory the evidence already available: customer language, query data,
   profile details, reviews, analytics, call notes, sales objections, and any
   public source that can support a claim.
3. Decide which FLOW stage is blocking progress. If demand language is
   unclear, return to **Find**. If the brand is not corroborated off-site,
   work on **Leverage**. If the owned asset is hard to extract or trust,
   **Optimize**. If traffic exists but business impact is weak, move to
   **Win**.
4. Rewrite or rebuild only after the evidence is organized. The strongest
   assets usually come from a clear source table, not from a blank-page
   brainstorm.
5. Review the finished work against three readers: the buyer, the search
   engine, and the AI agent that may summarize or compare the business later.

## Measurement

Use a balanced scorecard. Track visibility indicators such as rankings,
impressions, local-pack presence, citations, and AI mentions, but connect them
to business indicators such as qualified leads, calls, form completions, sales
opportunities, assisted conversions, and recurring objections. If the page or
profile cannot be measured, add the measurement event before judging
performance.

## Common Failure Modes

- Publishing a statistic because it sounds familiar instead of because the
  source was loaded and dated.
- Treating AI visibility as a formatting trick while ignoring brand evidence,
  entity consistency, and off-site corroboration.
- Writing pages around company preferences instead of buyer questions and
  decision risk.
- Optimizing for traffic without defining the next qualified action.
- Reusing old examples when a generic or newly created example would be
  cleaner and more durable.

## AI Agent Prompt

```text
You are an SEO strategist using the FLOW model. For the asset named
"[asset name]", analyze the target audience, search surface, evidence
needed, entity facts, conversion goal, and risks. Return: priorities,
page or profile changes, source requirements, internal links,
measurement plan, and a list of claims that need verification before
publication.
```

## Quality Bar

- Public claims use verified sources or stay qualitative.

## Keyword Summary

Source: `keywords-2026-05-11.csv`
Rows: 7

## Top Keywords

- workflow automation software | volume 5400 | score 1260.0
- business process automation platform | volume 2900 | score 966.67
- zapier alternatives for teams | volume 2400 | score 480.0
- b2b workflow automation | volume 1900 | score 475.0
- approval workflow software | volume 1600 | score 400.0
- workflow management for startups | volume 700 | score 140.0
- workflow automation examples | volume 1300 | score 65.0

## Competitors

Source: `.raw/sources/dataforseo/competitors-2026-05-11.json`
- flowpilot.example | score 1.42 | appearances 4
- opsstack.example | score 1.18 | appearances 3
- processgrid.example | score 0.91 | appearances 2

## PAA Digest

Source: `.raw/sources/dataforseo/paa-digest-2026-05-11.md`

---
brain_schema: marketing-brain.v1
type: source
title: "PAA Mining Digest"
created: 2026-05-11
updated: 2026-05-11
tags:
  - source/dataforseo
  - paa
status: ready
---

# PAA Mining Digest

Mined 2 synthetic top-volume keywords. 2 unique PAA questions, 2 related searches.

## People Also Ask - by topic

### Definition / What-is

- (1x) **What is workflow automation software?** _seeds: workflow automation software_

### How / Guide

- (1x) **How do approval workflows reduce manual work?** _seeds: approval workflow software_

## Related Searches - top 100

- (1x) workflow automation examples _seeds: workflow automation software_
- (1x) best workflow automation tools _seeds: workflow automation software_
