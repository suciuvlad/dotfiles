# Go DDD Domain Modeling

Domain-Driven Design Lite rules for Go domain entities and business logic types.

## When to Apply

- Creating new domain entity types or value objects
- Modifying existing business logic types
- Working on domain models or entity structs
- Designing constructors, behavior methods, or domain errors

## Core Rules

### 1. Model Behaviors, Not Data

Domain types must expose methods that describe **business operations**, not setters/getters. Think "what can this entity do?" not "what fields does it have?"

Bad:
```go
h.SetState(hour.Available)
h.SetHasTrainingScheduled(false)
```

Good:
```go
if err := h.CancelTraining(); err != nil {
    return err
}
```

Ask: "Would a non-technical person understand this method name?" If your business says "cancel training," the method is `CancelTraining()`, not `SetStatus("canceled")`.

### 2. Exported Fields, Always Valid State

Domain types use **exported fields** — the repository adapter (not the struct) is the boundary. All validation happens in command handlers before the domain type is created.

```go
// internal/domain/item/model.go
package item

import (
    "time"
    "github.com/google/uuid"
)

type Item struct {
    ID          uuid.UUID
    Name        string
    Description *string   // optional: *T pointer, not sql.NullString
    CreatedAt   time.Time
    UpdatedAt   time.Time
}
```

Validation lives in the command handler:
```go
func (h CreateItemHandler) Handle(ctx context.Context, cmd CreateItemCommand) (*item.Item, error) {
    if cmd.Name == "" {
        return nil, item.ErrNameRequired
    }
    i := &item.Item{ID: uuid.New(), Name: cmd.Name}
    // ...
}
```

### 3. Business Methods Return Errors for Invalid Operations

Each behavior method checks preconditions and returns a **domain-specific error** using `go-commons/errors` if the operation is not allowed.

```go
var ErrHourNotAvailable = &errors.Error{
    Type:    errors.ErrorTypeInvalid,
    Code:    "hour-not-available",
    Message: "hour is not available",
}

func (h *Hour) ScheduleTraining() error {
    if !h.IsAvailable() {
        return ErrHourNotAvailable
    }
    h.Availability = TrainingScheduled
    return nil
}
```

### 4. Domain Types Are Database-Agnostic

Domain types must have **zero** database dependencies — no `gorm:` struct tags, no ORM annotations, no database client imports. The domain package is pure business logic.

The GORM model lives in the adapter layer with explicit conversion functions:

```go
// adapters/psql/item_repository.go
type itemModel struct {
    ID          uuid.UUID `gorm:"type:uuid;primaryKey"`
    Name        string    `gorm:"not null"`
    Description *string
    CreatedAt   time.Time
    UpdatedAt   time.Time
}

func toItem(m itemModel) *item.Item { ... }
func toItemModel(i *item.Item) itemModel { ... }
```

### 5. Use Value Objects for Type Safety

Prefer custom types over primitives for domain concepts that have business meaning. Prevents passing arguments in the wrong order.

```go
type UserType struct{ s string }

var (
    Trainer  = UserType{"trainer"}
    Attendee = UserType{"attendee"}
)

func (u UserType) IsZero() bool { return u == UserType{} }
```

### 6. Domain Package Structure

Organize by **bounded context**, not by entity. A bounded context is a logical boundary within which a specific domain model and ubiquitous language apply. Multiple related entities live in the same context.

```
internal/domain/
    catalog/            // bounded context: everything about the product catalog
        item.go         // Item entity
        category.go     // Category entity (related concept, same language)
        errors.go       // go-commons/errors for this context
        repository.go   // Repository interface(s) for this context
    ordering/           // bounded context: purchase and fulfillment
        order.go
        order_line.go
        errors.go
        repository.go
```

Ask: "Do these concepts share the same ubiquitous language and evolve together?" If yes, they belong in the same bounded context. If they'd need translation to talk to each other, they belong in separate contexts.

For a simple single-purpose service, the entire service may represent one bounded context — one package under `internal/domain/` is fine.

## When NOT to Apply

- Simple CRUD services with no business rules — don't over-engineer
- Data-oriented services that mostly aggregate/pass-through data
- If the domain logic fits in < 20 lines, a plain struct with exported fields is fine
