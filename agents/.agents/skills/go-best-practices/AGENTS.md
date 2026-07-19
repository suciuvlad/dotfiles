# Go Best Practices -- Quick Reference

Compact reference for Go service architecture. For full explanations and code examples, read the individual rule files linked below.

---

## Architecture (CRITICAL)

**File:** `rules/architecture.md`

- Four layers: **domain** (pure logic, zero deps) -> **app** (orchestration) -> **ports** (HTTP/gRPC entry) -> **adapters** (DB/API exit)
- Domain cannot import app/ports/adapters. App cannot import ports/adapters.
- Collect all command/query handlers in a single `Application` struct
- Define interfaces next to the code that uses them, not next to the implementation
- Wire everything in `main.go` with plain constructors -- no DI frameworks
- Validate all dependencies in constructors; panic on nil (programming errors, not runtime)
- Ports are thin: parse request, call app, format response -- zero business logic
- Return typed errors from app layer; ports translate to HTTP/gRPC status codes

## Domain Modeling (CRITICAL)

**File:** `rules/domain-modeling.md`

- Exported fields — GORM adapter is the boundary, not the domain struct
- Validation lives in the command handler, not in the constructor
- Expose business operations (`ScheduleTraining()`), not setters (`SetStatus()`)
- Return `go-commons/errors` errors from behavior methods — no raw `errors.New()`
- Zero database dependencies in domain types -- no `gorm:` or `db:` tags
- Use value objects (custom types) over primitives for domain concepts

## CQRS (HIGH)

**File:** `rules/cqrs-commands-queries.md`
.
- Commands modify state, return only errors. Queries return data, modify nothing.
- Each command/query: input struct + handler struct with `Handle` method
- Name using business verbs (`ScheduleItem`), not CRUD (`CreateItem`)
- Optional command inputs use `*T`; domain model optional fields use `*T`
- Use `slog.Logger` in handlers for observability (logging, tracing)

## Repository Pattern (HIGH)

**File:** `rules/repository-pattern.md`

- Interface lives in domain package, GORM implementation in `adapters/psql/`
- Private `itemModel` struct with GORM tags stays inside the adapter
- Explicit `toItem()` / `toItemModel()` converters — no shared structs across layers
- Translate `gorm.ErrRecordNotFound` → domain `ErrNotFound` in the adapter
- Always provide an in-memory implementation for tests/prototyping
- Store values (not pointers) in in-memory maps to prevent uncommitted leaks

## Model Separation (HIGH)

**File:** `rules/model-separation.md`

- Three models: domain (business logic), database (persistence), API (presentation)
- DRY applies to behaviors, not data -- separate structs prevent cross-layer coupling
- Ask: "Will these two uses change for the same reason?" If no, separate them.

## Project Structure (CRITICAL)

**File:** `rules/project-structure.md`

- Services scaffold from `gonew github.com/purposeinplay/go-starter-openapi`
- Layers: `internal/domain` → `internal/app` → `internal/adapters/psql` → `internal/ports/openapi`, wired in `internal/service`
- Domain packages are organized by **bounded context**, not by entity — multiple related entities share one package
- Domain fields are exported (GORM model is the boundary, not the domain struct)
- Command/query file naming: `<business-verb>_<entity>.go`, handler naming: `<Verb><Entity>Handler`
- Go 1.24+ `tool` directive in `go.mod` -- no `tools.go` file

## Errors & Nullables (CRITICAL)

**File:** `rules/errors-and-nullables.md`

- Use `github.com/purposeinplay/go-commons/errors` -- never raw `errors.New()` in domain
- `&errors.Error{Type, Code, Message}` -- `Type` maps to HTTP status automatically
- Domain errors: return directly. Infrastructure errors: wrap with `fmt.Errorf("...: %w", err)`
- Translate `gorm.ErrRecordNotFound` → domain `ErrNotFound` in the adapter
- Use `*T` pointers for all optional fields — domain model, command inputs, GORM columns
- Never use `sql.NullString` or similar -- they leak infrastructure into domain
- Never use `opt/null` or `null.Val[T]`

## Monetary Amounts (HIGH)

**File:** `rules/monetary-amounts.md`

- Postgres: `NUMERIC(38, 18)` for every monetary column — never `BIGINT` (overflows past 9.2 ETH-as-wei) or `DOUBLE PRECISION` (lossy)
- GORM: `decimal.Decimal` (NOT NULL) or `*decimal.Decimal` (nullable) — **not** `decimal.NullDecimal`, to keep the project-wide `*T` nullable convention
- Domain: same `decimal.Decimal` / `*decimal.Decimal` — no translation at the repository boundary; `shopspring/decimal` is allowed in domain (value-object, like `uuid`)
- Wire (gRPC, REST, Kafka): amounts as `string`, parsed with `decimal.NewFromString`, emitted with `.String()` — int64 on the wire reintroduces overflow
- OpenAPI: `type: string` with `pattern: ^-?\d+(\.\d+)?$`; alias to `decimal.Decimal` via `x-go-type` for oapi-codegen
- Migration: `BIGINT → NUMERIC(38, 18)` divides by `10^decimals` if the BIGINT held subunits; rename misleading legacy columns (`amount_cents` → `amount`)
- Never `.IntPart()` on amounts (silently truncates int64); never `float` anywhere; round at the provider boundary (`RoundBank`), not at storage
- Tests: `decimal.RequireFromString`, compare with `.Equal` not `==`

## OpenAPI-First (HIGH)

**File:** `rules/openapi-first.md`

- Edit `openapi.yaml` first; run `go generate ./internal/ports/openapi/` to regenerate
- Never edit `openapi.gen.go` directly -- it is protected and will be overwritten
- No `x-stoplight` extensions in the spec
- Response bodies wrap data: `{"data": <payload>}`
- Handlers implement `StrictServerInterface` -- delegate immediately to app layer, zero business logic
- Use `go tool oapi-codegen` (Go 1.24+ tool directive, not `go run`)

## Service Wiring (HIGH)

**File:** `rules/service-wiring.md`

- Config: `github.com/caarlos0/env` — struct tags (`env:"..."`, `envDefault:"..."`), no YAML, no `--config` flag
- DB: GORM + exponential backoff retry in `adapters/psql/client.go`
- Migrations: `golang-migrate`, SQL files in `sql/migrations/N_<desc>.{up,down}.sql`
- `internal/service/application.go` is the only place concrete adapters are constructed
- Shutdown: `signal.NotifyContext` only -- no second `signal.Notify` or `signalChan`
- HTTP server: `github.com/purposeinplay/go-commons/httpserver`

## Security by Design (HIGH)

**File:** `rules/security-by-design.md`

- Require `User` parameter on all repository methods accessing user-owned data
- Authorization check inside repository, after fetch, before return — impossible to skip
- Return `go-commons/errors` with `ErrorTypeForbidden` from domain auth functions
- Separate `BySystem` methods for internal operations (cron, migrations, event consumers)
- Never pass auth via `context.Context` — loses type safety

## Testing Patterns (MEDIUM)

**File:** `rules/testing-patterns.md`

- Domain unit tests: black-box (`_test` package), no mocks, high coverage
- App layer tests: simple struct mocks, table-driven, `t.Parallel()`
- Integration tests: real DB, same test suite for all repository implementations
- Test transactions (rollback) and concurrent access (optimistic locking)
- Use `require` for errors (stops test), `assert` for values (continues)
