# Go CQRS (Command Query Responsibility Segregation)

Separate write operations (commands) from read operations (queries) in Go application layers.

## When to Apply

- Building or refactoring application-layer use cases
- Implementing command handlers for write operations
- Implementing query handlers for read operations
- Structuring application services with the CQRS pattern

## Core Principle

**Commands** modify state and return only errors. **Queries** return data and modify nothing.

## Command Handler Template

Each command is a struct defining inputs + a handler struct with a `Handle` method.

```go
// internal/app/command/schedule_item.go
package command

type ScheduleItemCommand struct {
    Name        string
    Description *string       // optional input: *T, not null.Val[T]
}

type ScheduleItemHandler struct {
    logger *slog.Logger
    repo   item.Repository
}

func NewScheduleItemHandler(logger *slog.Logger, repo item.Repository) ScheduleItemHandler {
    if logger == nil {
        panic("missing logger")
    }
    if repo == nil {
        panic("missing item.Repository")
    }
    return ScheduleItemHandler{logger: logger, repo: repo}
}

func (h ScheduleItemHandler) Handle(ctx context.Context, cmd ScheduleItemCommand) (*item.Item, error) {
    // 1. Validate
    if cmd.Name == "" {
        return nil, item.ErrNameRequired
    }

    // 2. Build domain object
    i := &item.Item{
        ID:          uuid.New(),
        Name:        cmd.Name,
        Description: cmd.Description,  // *string → *string, direct assignment
    }

    // 3. Persist
    if err := h.repo.Create(ctx, i); err != nil {
        return nil, fmt.Errorf("schedule item: %w", err)
    }

    h.logger.InfoContext(ctx, "item scheduled", "id", i.ID)
    return i, nil
}
```

## Query Handler Template

Queries read data — they never mutate state.

```go
// internal/app/query/get_item.go
package query

type GetItemQuery struct {
    ID uuid.UUID
}

type GetItemHandler struct {
    logger *slog.Logger
    repo   item.Repository
}

func NewGetItemHandler(logger *slog.Logger, repo item.Repository) GetItemHandler {
    if repo == nil {
        panic("missing item.Repository")
    }
    return GetItemHandler{logger: logger, repo: repo}
}

func (h GetItemHandler) Handle(ctx context.Context, q GetItemQuery) (*item.Item, error) {
    i, err := h.repo.FindByID(ctx, q.ID)
    if err != nil {
        return nil, fmt.Errorf("get item: %w", err)
    }
    return i, nil
}
```

## Naming Conventions

Use **business verbs**, not CRUD operations:

| Bad (CRUD)        | Good (Business)               |
|-------------------|-------------------------------|
| `CreateTraining`  | `ScheduleTraining`            |
| `DeleteTraining`  | `CancelTraining`              |
| `UpdateTraining`  | `RequestTrainingReschedule`   |
| `UpdateStatus`    | `ApproveTrainingReschedule`   |
| `GetTrainings`    | `AllTrainings`                |

Go to your business people and listen to how they describe operations. That's your naming source. For generic infrastructure-level aggregates (e.g. internal config entries), CRUD verbs are acceptable when no meaningful business verb exists.

## File Naming

One file per operation, snake_case, business verb:

```
command/
    schedule_item.go      → ScheduleItemHandler
    cancel_item.go        → CancelItemHandler
    approve_reschedule.go → ApproveRescheduleHandler
query/
    get_item.go           → GetItemHandler
    list_items.go         → ListItemsHandler
```

## Cross-Cutting Concerns

Commands and queries are the ideal place for logging, metrics, and tracing via `slog` — consistent observability regardless of the delivery port (HTTP, gRPC, CLI).

```go
func (h ScheduleItemHandler) Handle(ctx context.Context, cmd ScheduleItemCommand) (result *item.Item, err error) {
    defer func() {
        h.logger.InfoContext(ctx, "ScheduleItem executed", "err", err, "id", func() any {
            if result != nil { return result.ID }
            return nil
        }())
    }()
    // ...
}
```

## Returning Created Entity ID

Generate the UUID before calling the handler, set it in the command. Return `201 Created` with a `Location` header:

```go
// In the HTTP port:
cmd := command.ScheduleItemCommand{
    Name: req.Body.Name,
}
result, err := h.app.Commands.ScheduleItem.Handle(ctx, cmd)
if err != nil { ... }

return ScheduleItem201JSONResponse{Data: toItemResponse(result)}, nil
```

## When NOT to Use CQRS

- Simple authentication flows (login/token exchange)
- Pure data pass-through with no business logic
- Services that are trivially simple

When in doubt, start with CQRS — the overhead is minimal (one struct + one handler per use case), and it scales well as complexity grows.
