---
name: go-best-practices
description: 'Go service architecture for purposeinplay services. Use when building, refactoring, or reviewing Go services — domain entities, repositories, command/query handlers, OpenAPI endpoints, GORM adapters, error handling, nullable fields, monetary amounts, or service wiring. Triggers on: DDD, CQRS, bounded context, domain model, repository, command handler, query handler, OpenAPI, oapi-codegen, GORM, go-commons, gonew, service wiring, clean architecture, nullable, go-starter-openapi, decimal, NUMERIC, money, balance, wallet, crypto, satoshi, wei, shopspring.'
license: MIT
metadata:
  author: purposeinplay
  version: "2.3.0"
  category: go
---

# Go Best Practices

Architecture, design, and implementation patterns for purposeinplay Go services. Based on DDD, CQRS, and Clean Architecture principles, extended with org-specific library conventions.

## Quick Reference

| Topic | Rule File | Key Decision | Priority |
|-------|-----------|--------------|----------|
| Layer structure | `architecture` | domain → app → adapters → ports, wired in `service/` | Critical |
| Domain entities | `domain-modeling` | Exported fields, bounded contexts, behavior methods | Critical |
| Write operations | `cqrs-commands-queries` | Business verbs, one file per operation, `slog` logging | Critical |
| DB access | `repository-pattern` | Interface in domain, private GORM model in adapter | Critical |
| Model isolation | `model-separation` | Three separate structs: domain, DB, API | High |
| Package layout | `project-structure` | `go-starter-openapi` scaffold, Go 1.24 tool directive | High |
| Errors & nullables | `errors-and-nullables` | `go-commons/errors` with ErrorType, `*T` pointers | High |
| Monetary amounts | `monetary-amounts` | `NUMERIC(38, 18)` + `shopspring/decimal` end-to-end, strings on the wire | High |
| API endpoints | `openapi-first` | Edit `openapi.yaml` first, then `go generate`, then handler | High |
| Service setup | `service-wiring` | caarlos0/env config, GORM+backoff, golang-migrate, signal.NotifyContext | Medium |
| Authorization | `security-by-design` | User param on every repo method, `ErrorTypeForbidden` | Medium |
| Tests | `testing-patterns` | Black-box domain tests, table-driven app tests, real DB integration | Medium |

## When to Load Rule Files

Load individual rule files on demand based on the task at hand. **Do NOT load all at startup.**

| Task | Load these rules |
|------|-----------------|
| Scaffolding a new service | `project-structure`, `architecture`, `service-wiring` |
| Adding a domain entity | `domain-modeling`, `errors-and-nullables`, `repository-pattern` |
| Implementing a command/query | `cqrs-commands-queries`, `model-separation` |
| Adding an API endpoint | `openapi-first`, `model-separation`, `errors-and-nullables` |
| Writing a GORM adapter | `repository-pattern`, `model-separation` |
| Storing or moving monetary amounts | `monetary-amounts`, `errors-and-nullables`, `repository-pattern` |
| Adding authorization | `security-by-design`, `repository-pattern` |
| Writing tests | `testing-patterns`, `testing-integration` |
| Reviewing existing code | Start with `architecture`, then load rules relevant to issues found |

```
rules/architecture.md
rules/domain-modeling.md
rules/cqrs-commands-queries.md
rules/repository-pattern.md
rules/model-separation.md
rules/project-structure.md
rules/errors-and-nullables.md
rules/openapi-first.md
rules/service-wiring.md
rules/monetary-amounts.md
rules/security-by-design.md
rules/testing-patterns.md
rules/testing-integration.md
```

For a compact summary without code examples: [AGENTS.md](AGENTS.md)

## Workflow

When building a new feature end-to-end, follow this order:

1. **Domain first** — define entities and repository interface in `internal/domain/<context>/`
2. **Migrations** — create `sql/migrations/N_<desc>.{up,down}.sql` for the schema
3. **Adapter** — implement the repository in `internal/adapters/psql/` with a private GORM model
4. **Application** — add command/query handlers in `internal/app/command/` and `internal/app/query/`
5. **Wire** — register handlers in `internal/app/app.go` and `internal/service/application.go`
6. **API spec** — edit `internal/ports/openapi/openapi.yaml`, then run `go generate ./internal/ports/openapi/`
7. **Handler** — implement the generated interface in `internal/ports/openapi/handler.go`
8. **Test** — domain unit tests, then integration tests with a real database

> **Important:** Never skip from domain straight to handler. The layer order exists because each layer depends only on the one above it. Skipping creates coupling that breaks the architecture.

## New Feature Checklist

Adding a new entity to an existing bounded context:
- [ ] Add entity struct to `internal/domain/<context>/` — no infra imports
- [ ] Add error constants/vars to `internal/domain/<context>/errors.go`
- [ ] Add methods to `internal/domain/<context>/repository.go` interface
- [ ] `internal/app/command/<verb>_<entity>.go` — one file per mutation
- [ ] `internal/app/query/<verb>_<entity>.go` — one file per read
- [ ] `internal/app/app.go` — add to Commands/Queries structs
- [ ] `internal/adapters/psql/<context>_repository.go` — implement new methods
- [ ] `sql/migrations/N_<desc>.{up,down}.sql`
- [ ] `internal/ports/openapi/openapi.yaml` — add endpoints
- [ ] `go generate ./internal/ports/openapi/` — regenerate
- [ ] `internal/ports/openapi/handler.go` — implement new methods
- [ ] `internal/service/application.go` — wire new handlers

Adding a new bounded context:
- [ ] Create `internal/domain/<context>/` package with entities, errors, repository interface
- [ ] Create `internal/adapters/psql/<context>_repository.go` with GORM impl and private model
- [ ] Add commands/queries to `internal/app/`
- [ ] Add to `internal/app/app.go` Commands/Queries structs
- [ ] Wire in `internal/service/application.go`

## Expected Output

When this skill guides code generation, the result should be:

- **Compilable** — `go build ./...` passes with no errors
- **Properly layered** — domain has zero infrastructure imports, adapters import only domain
- **Spec-first** — OpenAPI changes reflected in `openapi.yaml` before handler code
- **Generated code committed** — `openapi.gen.go` is committed so the template compiles without tools
- **Migrations paired** — every `.up.sql` has a matching `.down.sql`

## Error Handling

| Scenario | Action |
|----------|--------|
| Domain validation failure | Return `&errors.Error{Type: ErrorTypeInvalid, Code: ..., Message: ...}` directly — no wrapping |
| Record not found in adapter | Translate `gorm.ErrRecordNotFound` → domain `ErrNotFound` sentinel |
| Infrastructure error in adapter | Wrap with `fmt.Errorf("operation: %w", err)` |
| Error in HTTP handler | Call `mapError(err)` which uses `appErr.Type.HTTPStatus()` |
| Optional domain field | Use `*T` pointer — never `sql.Null*` or `opt/null` |
| Missing required field in command | Return domain error (e.g. `ErrNameRequired`) before calling repo |
