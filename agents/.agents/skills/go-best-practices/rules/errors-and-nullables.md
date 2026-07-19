# Errors and Nullable Fields

Structured error handling and nullable value conventions for purposeinplay Go services.

## When to Apply

- Defining domain errors for a new aggregate
- Handling errors in command/query handlers or HTTP ports
- Deciding how to represent an optional field in a struct

---

## Errors: go-commons/errors

Always use `github.com/purposeinplay/go-commons/errors`. Never define raw `errors.New(...)` sentinel vars or custom error structs in domain packages.

### Domain errors file

```go
// internal/domain/<aggregate>/errors.go
package <aggregate>

import "github.com/purposeinplay/go-commons/errors"

const (
    ErrorCodeNotFound     errors.ErrorCode = "<aggregate>-not-found"
    ErrorCodeNameRequired errors.ErrorCode = "<aggregate>-name-required"
)

var (
    ErrNotFound = &errors.Error{
        Type:    errors.ErrorTypeNotFound,
        Code:    ErrorCodeNotFound,
        Message: "<aggregate> not found",
    }
    ErrNameRequired = &errors.Error{
        Type:    errors.ErrorTypeInvalid,
        Code:    ErrorCodeNameRequired,
        Message: "<aggregate> name is required",
    }
)
```

### ErrorType → HTTP Status mapping

| ErrorType | HTTP Status |
|-----------|------------|
| `ErrorTypeNotFound` | 404 |
| `ErrorTypeInvalid` | 400 |
| `ErrorTypeUnauthorized` | 401 |
| `ErrorTypeForbidden` | 403 |
| `ErrorTypeInternal` | 500 |

Call `appErr.Type.HTTPStatus()` in the HTTP port to map automatically.

### Error handling in command handlers

Validate input and return domain errors directly. Wrap infrastructure errors with `fmt.Errorf`.

```go
func (h CreateItemHandler) Handle(ctx context.Context, cmd CreateItemCommand) (*item.Item, error) {
    if cmd.Name == "" {
        return nil, item.ErrNameRequired  // domain error — no wrapping
    }

    i := &item.Item{ID: uuid.New(), Name: cmd.Name}

    if err := h.repo.Create(ctx, i); err != nil {
        return nil, fmt.Errorf("create item: %w", err)  // infra error — wrap
    }

    return i, nil
}
```

### Error mapping in HTTP handlers

```go
func mapError(err error) (int, ErrorResponse) {
    var appErr *commonserrors.Error
    if errors.As(err, &appErr) {
        return appErr.Type.HTTPStatus(), ErrorResponse{
            Code:    string(appErr.Code),
            Message: appErr.Message,
        }
    }
    return http.StatusInternalServerError, ErrorResponse{
        Code:    "internal-error",
        Message: "internal server error",
    }
}
```

Never return raw Go error messages (e.g., `err.Error()`) to HTTP clients.

### Adapter error mapping

In the GORM repository, translate `gorm.ErrRecordNotFound` to the domain sentinel:

```go
if errors.Is(err, gorm.ErrRecordNotFound) {
    return nil, item.ErrNotFound
}
return nil, fmt.Errorf("find item: %w", err)
```

---

## Nullable Fields: Pointers

Use `*T` pointers for all optional fields — in domain models, command inputs, GORM models, and generated OpenAPI types. This is consistent, zero-dependency, and idiomatic Go.

| Context | Type | Example |
|---------|------|---------|
| Domain model optional field | `*T` | `Description *string` |
| Command/query optional input | `*T` | `Description *string` |
| GORM model optional column | `*T` | `Description *string` |
| Monetary amount (optional) | `*decimal.Decimal` | `PendingCredit *decimal.Decimal` |
| OpenAPI optional field | `*T` (generated) | follows spec |

Because domain and GORM both use `*T`, the converter functions are a simple field copy — no conversion layer needed for optional fields.

### Working with optional fields

```go
// Build domain object from command input — direct assignment
i := &item.Item{
    ID:          uuid.New(),
    Name:        cmd.Name,
    Description: cmd.Description,  // *string → *string, no conversion
}

// Check and read
if i.Description != nil {
    s := *i.Description
}

// Set a new value
desc := "some text"
i.Description = &desc
```

### Never use sql.Null* types

Bad:
```go
Description sql.NullString  // leaks database/sql into domain
```

Good:
```go
Description *string  // everywhere: domain, GORM model, command input
```

`sql.Null*` types import `database/sql` which is an infrastructure concern and must not appear in domain or app layer packages.

The same logic applies to `decimal.NullDecimal` — even though it doesn't pull in `database/sql`, it's a `{Decimal, Valid}` shape that bifurcates the project's nullable convention. Use `*decimal.Decimal` instead. See `monetary-amounts.md` for the full pattern.