---
brain_schema: marketing-brain.v1
type: deliverable
title: "ULTIMATE BEAST Plan"
created: 2026-05-11
updated: 2026-05-11
tags:
  - deliverable
  - beast-plan
status: ready-for-review
business_type: saas
owner: "Strategy Owner"
confidence: medium
approval_status: needs-review
rollback_note: "Do not prune, redirect, publish, or migrate until source rows and owner approval are verified."
risk_level: medium
sources:
  - "keywords-2026-05-11.csv"
  - ".raw/sources/dataforseo/competitors-2026-05-11.json"
  - ".raw/sources/dataforseo/paa-digest-2026-05-11.md"
  - "references/current-search-requirements-2026-05-11.md"
  - ".raw/sources/beast-plan-context-2026-05-11.md"
---

# ULTIMATE BEAST Plan

Client: **Demo Growth Co**
Site: **https://www.example.com**
Business type: **saas**
Generated: **2026-05-11**

## Executive Summary

This plan is a source-cited operating draft. It should be reviewed against Search Console, analytics, crawl data, and the live site before implementation. The strongest immediate path is to close the measurement gate, protect already-working URLs, consolidate cannibalized intent, and prioritize pages where competitor demand is visible and the current site is not already winning.

The current keyword surface contains **7** deduplicated opportunities. The top visible opportunity score is **1260.00**. The competitor set contains **3** ranked domains from the latest competitor pull.

## Search And AI Feature Ground Rules

Google's current guidance says normal SEO fundamentals apply to AI Overviews and AI Mode, no special AI-only schema or machine-readable file is required, and Search Console reports AI feature traffic inside the overall Web performance data. This plan therefore optimizes for crawlability, index eligibility, helpful content, source clarity, internal links, structured data accuracy, and measurement quality rather than promising AI Overview inclusion.

## Find: Market And Competitor Signals

Top competitor signals from the latest pull:

1. **flowpilot.example** — score 1.42, appearances 4, average position 3.2.
2. **opsstack.example** — score 1.18, appearances 3, average position 4.1.
3. **processgrid.example** — score 0.91, appearances 2, average position 6.0.

## Leverage: Keyword Opportunities

| keyword | volume | best competitor | our position | opportunity | intent |
|---|---:|---|---:|---:|---|
| workflow automation software | 5400 | flowpilot.example #2 | 18 | 1260.0 | commercial |
| business process automation platform | 2900 | opsstack.example #2 |  | 966.67 | commercial |
| zapier alternatives for teams | 2400 | flowpilot.example #4 |  | 480.0 | commercial |
| b2b workflow automation | 1900 | flowpilot.example #3 |  | 475.0 | commercial |
| approval workflow software | 1600 | processgrid.example #3 | 52 | 400.0 | commercial |
| workflow management for startups | 700 | processgrid.example #4 |  | 140.0 | commercial |
| workflow automation examples | 1300 | flowpilot.example #5 | 9 | 65.0 | informational |

High-volume demand to protect or investigate:

- **workflow automation software** — volume 5400, current URL `https://www.example.com/platform`.
- **business process automation platform** — volume 2900, current URL `not ranking`.
- **zapier alternatives for teams** — volume 2400, current URL `not ranking`.
- **b2b workflow automation** — volume 1900, current URL `not ranking`.
- **approval workflow software** — volume 1600, current URL `https://www.example.com/approval`.
- **workflow automation examples** — volume 1300, current URL `https://www.example.com/blog/examples`.
- **workflow management for startups** — volume 700, current URL `not ranking`.

## Optimize: Page And Content Actions

1. Complete Day 0 measurement access before any irreversible recommendation.
2. Map every target keyword to exactly one canonical URL owner.
3. Refresh existing owner URLs before publishing competing same-intent pages.
4. Consolidate or prune only after GSC loss data, crawl status, backlink risk, and conversion impact are checked.
5. Add first-hand evidence, author/source proof, visuals, examples, and structured data that matches visible page content.

## Win: 30-Day Execution Roadmap

| window | outcome | required evidence | rollback |
|---|---|---|---|
| Days 0-2 | Measurement gate closed | GSC, GA4, crawl, CMS/source access | Pause optimization claims |
| Days 3-7 | Keyword-to-URL ownership map | Workbook rows, current URLs, SERP intent | Revert owner assignment |
| Days 8-14 | Refresh/prune shortlist | GSC exports, crawl/index data, content QA | Restore prior page/redirect state |
| Days 15-21 | New or refreshed hero pages | Briefs, source notes, approval record | Unpublish or revert page |
| Days 22-30 | Report and next sprint | Scorecard, action log, open risks | Keep sprint in review |

## PAA And Content Gap Notes

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

## Action Queue

| action | source | confidence | owner | approval | rollback |
|---|---|---|---|---|---|
| Close Day 0 measurement access | `wiki/flows/Day 0 Measurement Access Gate.md` | high | Strategy Owner | needs-review | Keep recommendations as hypotheses |
| Verify top 12 keyword owner URLs | latest keyword CSV | medium | Strategy Owner | needs-review | Revert keyword map entries |
| Inspect top competitor page formats | latest competitors JSON | medium | Strategy Owner | needs-review | Remove unsupported competitor assumptions |
| Build next 30-day sprint board | this BEAST plan | medium | Strategy Owner | needs-review | Return sprint to draft |

## Source Manifest

- `keywords-2026-05-11.csv`
- `.raw/sources/dataforseo/competitors-2026-05-11.json`
- `.raw/sources/dataforseo/paa-digest-2026-05-11.md`
- `references/current-search-requirements-2026-05-11.md`
- `.raw/sources/beast-plan-context-2026-05-11.md`

## Review Status

This deliverable is ready for human review, not direct implementation. Any prune, redirect, migration, publication, or measurement change still needs owner approval and rollback evidence.
