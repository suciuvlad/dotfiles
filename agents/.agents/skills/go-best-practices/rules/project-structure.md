# purposeinplay Go Project Structure

Package layout and layer rules for services scaffolded from `go-starter-openapi`.

## When to Apply

- Creating a new service with `gonew`
- Adding a new aggregate (entity + repository + handlers)
- Deciding which package a new file belongs in

## Directory Layout

```
internal/
  domain/
    <bounded-context>/  # e.g. catalog/, ordering/ — NOT one package per entity
      item.go           # Entity within this context
      category.go       # Another entity in the same context
      errors.go         # go-commons/errors constants and vars
      repository.go     # Repository interface(s) for this context
  app/
    app.go              # Application struct: Commands + Queries
    command/
      create_<agg>.go   # One file per write operation
      update_<agg>.go
      delete_<agg>.go
    query/
      get_<agg>.go      # One file per read operation
      list_<agg>s.go
  adapters/
    psql/
      client.go         # Connect() with exponential backoff
      dsn.go            # ComposeDSN()
      migrations.go     # RunMigrations()
      <agg>_repository.go  # GORM implementation
  ports/
    openapi/
      openapi.yaml      # Source of truth — edit this, not the generated file
      openapi.gen.go    # GENERATED — never edit directly
      handler.go        # StrictServerInterface implementation
  service/
    config.go           # caarlos0/env config loading
    application.go      # NewApplication() — wires adapters into app.Application
cmd/
  root.go               # cobra root command
  server.go             # server start/stop
sql/
  migrations/
    1_initial_schema.up.sql
    1_initial_schema.down.sql
main.go                 # Delegates to cmd.RootCmd
```

## Layer Import Rules

| Layer | May import | Must NOT import |
|-------|-----------|-----------------|
| `domain` | stdlib, uuid, shopspring/decimal, `go-commons/errors` | `app`, `adapters`, `ports`, `service`, gorm, net/http |
| `app` | `domain`, stdlib, `slog` | `adapters`, `ports`, `service`, gorm, net/http |
| `adapters` | `domain`, gorm, stdlib | `app`, `ports`, `service` |
| `ports` | `app`, `domain`, generated openapi types | `adapters`, `service` |
| `service` | all internal packages | (wiring layer — imports everything) |

## Domain Package Conventions

Packages are organized by **bounded context** — a logical boundary with a consistent ubiquitous language. Multiple related entities live in the same package. Fields are **exported** because the GORM adapter is the boundary, not the domain struct.

```go
// internal/domain/catalog/item.go
package catalog

import (
    "time"
    "github.com/google/uuid"
)

type Item struct {
    ID          uuid.UUID
    Name        string
    Description *string   // optional field: *T pointer
    CreatedAt   time.Time
    UpdatedAt   time.Time
}

// Category lives in the same bounded context as Item
type Category struct {
    ID   uuid.UUID
    Name string
}
```

A single-purpose service (like `go-starter-openapi`) may have just one bounded context — one package under `internal/domain/` is fine.

## Command/Query Handler Naming

File name: `<verb>_<aggregate>.go` (snake_case, business verb).
Handler name: `<Verb><Aggregate>Handler` (PascalCase business verb).

Use **business verbs**, not CRUD:

```
schedule_item.go   → ScheduleItemHandler    (not create_item)
cancel_item.go     → CancelItemHandler      (not delete_item)
approve_item.go    → ApproveItemHandler     (not update_item)
get_item.go        → GetItemHandler
list_items.go      → ListItemsHandler
```

Go to your business people and listen to how they describe operations — that's your naming source. For generic infrastructure-level aggregates where no meaningful business verb exists, CRUD verbs are acceptable.

## Go Module Tool Dependencies

Use Go 1.24+ `tool` directive — no `tools.go` file:

```bash
# Add a tool dependency
go get -tool github.com/oapi-codegen/oapi-codegen/v2/cmd/oapi-codegen
```

The `go.mod` `tool` block lists all tool dependencies alongside regular dependencies.

## Starting a New Service

```bash
gonew github.com/purposeinplay/go-starter-openapi github.com/purposeinplay/<service-name>
cd <service-name>
go mod tidy
```

`gonew` rewrites the module path in `go.mod` and all Go import paths automatically.
