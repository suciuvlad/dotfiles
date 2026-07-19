# Go Clean Architecture (Ports & Adapters)

Clean Architecture combined with DDD and CQRS for Go services. Covers layer separation, dependency rules, and end-to-end wiring.

## When to Apply

- Creating a new Go service or microservice
- Refactoring an existing service into clean layers
- Adding features that span multiple concerns (HTTP, database, business logic)
- Wiring together domain, application, ports, and adapters end-to-end

## Layer Structure

```
internal/
    domain/
        <bounded-context>/    # e.g. catalog/, ordering/, identity/
            item.go           # Entity within this context
            category.go       # Another entity in the same context
            errors.go         # go-commons/errors for this context
            repository.go     # Repository interface(s) for this context
    app/
        app.go                # Application struct: Commands + Queries
        command/
            schedule_item.go  # Command struct + handler
        query/
            get_item.go       # Query struct + handler
    adapters/
        psql/
            client.go         # Connect() with exponential backoff
            <context>_repository.go  # GORM implementation
    ports/
        openapi/
            openapi.yaml      # Source of truth
            openapi.gen.go    # Generated — never edit directly
            handler.go        # StrictServerInterface implementation
    service/
        config.go             # caarlos0/env config loading
        application.go        # NewApplication() — wires everything
```

## Layer Rules

### Domain (innermost)
- Knows nothing about other layers
- No imports from `app`, `ports`, `adapters`, or `service`
- No database, HTTP, or framework dependencies
- Contains: entity types, business rules, repository interfaces, domain errors

### Application
- Can import `domain`
- Cannot import `ports`, `adapters`, or `service`
- No idea if called from HTTP, gRPC, or CLI
- No idea which database is used
- Contains: command handlers, query handlers

### Ports (entry points)
- Can import `app` and `domain`
- Cannot import `adapters` or `service` directly
- Contains: HTTP handlers (via oapi-codegen strict-server)

### Adapters (exit points)
- Can import `domain`
- Contains: GORM repositories, external service clients

### Service (wiring)
- Imports everything — this is the only layer that does
- Contains: `NewApplication()`, config loading

## The Application Struct

Collect all command and query handlers in a single `Application` struct — the service's public API.

```go
// internal/app/app.go
package app

type Application struct {
    Commands Commands
    Queries  Queries
}

type Commands struct {
    ScheduleItem command.ScheduleItemHandler
    CancelItem   command.CancelItemHandler
}

type Queries struct {
    GetItem   query.GetItemHandler
    ListItems query.ListItemsHandler
}
```

## Dependency Injection in service/application.go

Wire everything together using plain constructors. No DI frameworks needed.

```go
// internal/service/application.go
func NewApplication(db *gorm.DB, logger *slog.Logger) app.Application {
    itemRepo := psql.ItemRepository{DB: db}

    return app.Application{
        Commands: app.Commands{
            ScheduleItem: command.NewScheduleItemHandler(logger, itemRepo),
            CancelItem:   command.NewCancelItemHandler(logger, itemRepo),
        },
        Queries: app.Queries{
            GetItem:   query.NewGetItemHandler(logger, itemRepo),
            ListItems: query.NewListItemsHandler(logger, itemRepo),
        },
    }
}
```

## Constructor Validation
Validate all dependencies in constructors. Panic on nil — these are programming errors, not runtime errors.

```go
func NewScheduleItemHandler(logger *slog.Logger, repo item.Repository) ScheduleItemHandler {
    if logger == nil {
        panic("missing logger")
    }
    if repo == nil {
        panic("missing item.Repository")
    }
    return ScheduleItemHandler{logger: logger, repo: repo}
}
```

## HTTP Port Template
Ports are thin — parse the request, call the application, format the response. Zero business logic.

```go
func (h *handler) ScheduleItem(ctx context.Context, req ScheduleItemRequestObject) (ScheduleItemResponseObject, error) {
    result, err := h.app.Commands.ScheduleItem.Handle(ctx, command.ScheduleItemCommand{
        Name: req.Body.Name,
    })
    if err != nil {
        return nil, err
    }
    return ScheduleItem201JSONResponse{Data: toItemResponse(result)}, nil
}
```

## Application-Layer Errors

Use `go-commons/errors` — `ErrorType` maps to HTTP status automatically. Never leak HTTP concepts into application code.

```go
// Domain: define the error
var ErrNotFound = &errors.Error{
    Type:    errors.ErrorTypeNotFound,
    Code:    "item-not-found",
    Message: "item not found",
}

// HTTP port: translate to status code
var appErr *commonserrors.Error
if errors.As(err, &appErr) {
    w.WriteHeader(appErr.Type.HTTPStatus()) // 404, 400, 403, 500
}
```

## Data Flow

```
HTTP Request
  -> Port (parse request, create command)
    -> Command Handler (validate, orchestrate)
      -> Domain Entity (business logic)
      -> Repository (persist via GORM adapter)
    <- Return domain error or result
  <- Port (map to HTTP response)
HTTP Response
```

## Step-by-Step: Building a New Feature

1. **Define the domain entity** — exported fields, `go-commons/errors` (see `domain-modeling.md`)
2. **Define the repository interface** in the domain package (see `repository-pattern.md`)
3. **Create command/query handlers** in the app layer (see `cqrs-commands-queries.md`)
4. **Add endpoint to `openapi.yaml`**, run `go generate` (see `openapi-first.md`)
5. **Implement the HTTP port handler** — thin, delegates to app
6. **Implement the GORM repository adapter** — private model struct (see `repository-pattern.md`)
7. **Wire in `service/application.go`** — create adapter, inject into handlers (see `service-wiring.md`)

## Key Principles Checklist

- [ ] Domain package has zero infrastructure imports
- [ ] Repository interface lives in the domain package
- [ ] Command/query handlers contain all validation and orchestration logic
- [ ] HTTP port handlers contain zero business logic
- [ ] All dependencies injected via constructors in `service/application.go`
- [ ] Errors use `go-commons/errors` with typed `ErrorType`
- [ ] GORM model struct is private in `adapters/psql/`

## When NOT to Apply

- Simple CRUD with no business logic, or services under 200 lines — one package is fine
