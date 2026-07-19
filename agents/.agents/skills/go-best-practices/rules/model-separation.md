# Go Model Separation (When to Avoid DRY)

Maintain separate models for API responses, database storage, and domain logic in Go services.

## When to Apply

- Deciding whether to share a struct across layers
- Creating API response models, database models, or domain models
- Adding a field that only one layer needs
- Encountering a "god struct" with json, db, and domain tags

## Core Principle

**DRY applies to behaviors, not data.** Sharing the same struct between your HTTP response, database model, and domain entity creates tight coupling. Changes to one concern force changes to all others.

## The Three Models

### 1. Domain Model (business logic)

Private fields, behavior methods, validated constructors. Lives in `domain/` package.

```go
// domain/training/training.go
type Training struct {
    uuid     string
    userUUID string
    userName string
    time     time.Time
    canceled bool
}

func (t Training) CanBeCanceledForFree() bool {
    return t.time.Sub(time.Now()) >= time.Hour*24
}
```

### 2. Database Model (persistence)

Has `db:` or `bson:` tags. Lives in `adapters/` package. Optimized for storage.

```go
// adapters/training_model.go
type trainingModel struct {
    UUID     string    `db:"uuid"`
    UserUUID string    `db:"user_uuid"`
    UserName string    `db:"user_name"`
    Time     time.Time `db:"time"`
    Canceled bool      `db:"canceled"`
}
```

### 3. API Response Model (presentation)

Has `json:` tags. Lives in `ports/` package or generated from OpenAPI spec. Optimized for the client.

```go
// Generated from OpenAPI or defined in ports
type Training struct {
    UUID               string     `json:"uuid"`
    User               string     `json:"user"`
    UserUuid           string     `json:"userUuid"`
    Notes              string     `json:"notes"`
    Time               time.Time  `json:"time"`
    CanBeCancelled     bool       `json:"canBeCancelled"`
    MoveRequiresAccept bool       `json:"moveRequiresAccept"`
}
```

## Mapping Between Models

### Domain <-> Database (in repository adapter)

```go
func (r *Repository) unmarshalTraining(dbModel trainingModel) (*training.Training, error) {
    return training.UnmarshalFromDatabase(
        dbModel.UUID,
        dbModel.UserUUID,
        dbModel.UserName,
        dbModel.Time,
        dbModel.Canceled,
    )
}

func (r *Repository) marshalTraining(tr *training.Training) trainingModel {
    return trainingModel{
        UUID:     tr.UUID(),
        UserUUID: tr.UserUUID(),
        UserName: tr.UserName(),
        Time:     tr.Time(),
        Canceled: tr.IsCanceled(),
    }
}
```

### Domain/Query -> API Response (in HTTP port)

```go
func trainingToResponse(tr query.Training) Training {
    return Training{
        UUID:               tr.UUID,
        User:               tr.UserName,
        UserUuid:           tr.UserUUID,
        Notes:              tr.Notes,
        Time:               tr.Time,
        CanBeCancelled:     tr.CanBeCancelled,
        MoveRequiresAccept: tr.MoveRequiresAccept,
    }
}
```

## When This Matters Most

### Adding a field to one layer only

Need to store the user's IP address without exposing it in the API:

```go
// Just add to the database model -- API model is unaffected
type userModel struct {
    Balance     int    `db:"balance"`
    DisplayName string `db:"display_name"`
    Role        string `db:"role"`
    LastIP      string `db:"last_ip"`  // new field, not in API
}
```

Without separation, you'd need hacks like:

```go
// BAD -- nil-ing out fields to hide them from the API
user.LastIP = nil
render.Respond(w, r, user)
```

### Evolving API independently of storage

Your database stores timestamps in UTC, but your API returns ISO 8601 strings. Your database uses normalized IDs, but your API returns embedded objects. Separate models handle this naturally.

### Different validation per layer

- Domain: "a training must have a non-empty UUID and a future time"
- Database: "UUID is a PRIMARY KEY, time is NOT NULL"
- API: "uuid is a required string in format uuid, time is required in format date-time"

## Decision Guide

Ask: **Will these two uses of the struct change for the same reason?**

- If yes (rare): share the struct (early prototype, trivial CRUD).
- If no (common): separate them. The "cost" is a few extra lines of mapping code. The benefit is independent evolution.

## Common Violations to Watch For

1. **OpenAPI types used as database models** -- API spec changes break your persistence
2. **Database structs returned from HTTP handlers** -- schema migration changes your API
3. **Domain types with `json` tags** -- presentation concerns leak into business logic
4. **One "god struct" used everywhere** -- changing anything risks breaking everything

## When Separation is Overkill

- The service is a trivial passthrough (no logic, just stores and retrieves)
- The project has < 1 month of expected lifetime
- There are fewer than 5 fields and no business logic
- You're in early prototype phase (but plan to separate before shipping)
