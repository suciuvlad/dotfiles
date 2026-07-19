# Go Secure by Design

Build authorization into repository interfaces so it is impossible to access data without proper permissions.

## When to Apply

- Creating or modifying repository methods that access user-owned data
- Implementing authorization checks for data access
- Designing repository interfaces with security constraints
- Adding system/internal operations that bypass user authorization

## Core Principle

**Make the compiler enforce authorization.** If `User` is a required parameter on `FindByOwner` and `Update`, no one can forget the auth check — it won't compile without it.

## Domain: Define Access Rules

Place the authorization logic in the domain layer as a pure function.

```go
// internal/domain/training/errors.go
package training

import "github.com/purposeinplay/go-commons/errors"

var ErrForbiddenToSeeTraining = &errors.Error{
    Type:    errors.ErrorTypeForbidden,
    Code:    "training-forbidden",
    Message: "user is not allowed to see this training",
}

// Pure function — testable, reusable
func CanUserSeeTraining(user User, training Training) error {
    if user.Type() == Trainer {
        return nil
    }
    if user.UUID() == training.UserUUID() {
        return nil
    }
    return ErrForbiddenToSeeTraining
}
```

## Repository: Require User on Every Method

Add `User` as a required parameter on all repository methods that access user-owned data.

```go
// internal/domain/training/repository.go
package training

type Repository interface {
    AddTraining(ctx context.Context, tr *Training) error

    GetTraining(
        ctx context.Context,
        trainingUUID string,
        user User,             // <-- required, compiler enforces it
    ) (*Training, error)

    UpdateTraining(
        ctx context.Context,
        trainingUUID string,
        user User,             // <-- required
        updateFn func(ctx context.Context, tr *Training) (*Training, error),
    ) error
}
```

## Repository Implementation: Check Before Returning

Call the domain authorization function **inside** the repository, after fetching but before returning.

```go
func (r TrainingRepository) GetTraining(
    ctx context.Context,
    trainingUUID string,
    user training.User,
) (*training.Training, error) {
    var m trainingModel
    if err := r.DB.WithContext(ctx).First(&m, "id = ?", trainingUUID).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, training.ErrNotFound
        }
        return nil, fmt.Errorf("get training: %w", err)
    }

    tr := toTraining(m)

    // Authorization check — happens automatically, impossible to skip
    if err := training.CanUserSeeTraining(user, *tr); err != nil {
        return nil, err
    }

    return tr, nil
}
```

## Collection Queries: Filter at Database Level

For list endpoints, filter by the authorized user at the **query level** — don't fetch all and filter in Go.

```go
func (r TrainingRepository) ListForUser(
    ctx context.Context,
    userUUID uuid.UUID,
) ([]*training.Training, error) {
    var models []trainingModel
    if err := r.DB.WithContext(ctx).
        Where("user_uuid = ? AND canceled = false", userUUID).
        Find(&models).Error; err != nil {
        return nil, fmt.Errorf("list trainings: %w", err)
    }
    // ...
}
```

## Internal/System Operations

For operations without a user context (cron jobs, migrations, event consumers), create **separate** repository methods with names that signal their security implications:

```go
type Repository interface {
    // User-facing — requires authorization
    GetTraining(ctx context.Context, id string, user User) (*Training, error)

    // Internal — no user check, name makes security implications explicit
    GetTrainingBySystem(ctx context.Context, id string) (*Training, error)
}
```

Or create CQRS commands per actor:

```go
type CancelTrainingHandler struct { ... }                 // for users
type CancelTrainingByOperationsHandler struct { ... }     // for ops/cron
```

## Anti-Patterns to Avoid

### Don't pass auth via context.Context

```go
// BAD — loses type safety, hides requirements, runtime panic if missing
func GetTraining(ctx context.Context, uuid string) (*Training, error) {
    user := ctx.Value("user").(User)
}

// GOOD — explicit, compile-time safe
func GetTraining(ctx context.Context, uuid string, user User) (*Training, error)
```

### Don't create "fake users" for system operations

```go
// BAD — leads to if-statement spaghetti
systemUser := User{Role: "system"}
repo.GetTraining(ctx, uuid, systemUser)

// GOOD — separate method with clear intent
repo.GetTrainingBySystem(ctx, uuid)
```

### Don't scatter authorization checks in HTTP handlers

```go
// BAD — easy to forget, duplicated across handlers
func (h *handler) GetTraining(ctx context.Context, req ...) (...) {
    tr := h.app.Queries.GetTraining.Handle(ctx, ...)
    if tr.UserUUID != user.UUID { // manual check, easy to miss
        return nil, errors.New("forbidden")
    }
}

// GOOD — auth is built into the repository, impossible to skip
func (h *handler) GetTraining(ctx context.Context, req ...) (...) {
    // GetTrainingQuery carries the user — auth happens in the repository
    tr, err := h.app.Queries.GetTraining.Handle(ctx, query.GetTrainingQuery{
        ID:   req.Id,
        User: userFromCtx(ctx),
    })
}
```
