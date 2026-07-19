# OpenAPI-First Development with oapi-codegen

Workflow and conventions for HTTP ports in purposeinplay Go services.

## When to Apply

- Adding a new HTTP endpoint
- Changing a request or response shape
- Implementing a generated `StrictServerInterface` method
- Reviewing HTTP handler code

## Core Rule: Spec First, Code Second

Always edit `openapi.yaml` before touching any Go code. The generated file `openapi.gen.go` is protected — the `protect-files` hook blocks direct edits.

```
openapi.yaml  →  go generate  →  openapi.gen.go  →  implement in handler.go
```

## Generate Command

The `//go:generate` directive lives at the top of `handler.go`:

```go
// nolint: revive
//go:generate go tool oapi-codegen -generate=models,chi-server,strict-server,spec -o openapi.gen.go -package=openapi openapi.yaml
```

Run with:
```bash
go generate ./internal/ports/openapi/
```

This uses the Go 1.24+ `tool` directive — `oapi-codegen` is declared in `go.mod` under `tool`, not in a `tools.go` file.

## openapi.yaml Conventions

- **No `x-stoplight` extensions** — they are not portable and will be rejected
- Response bodies always wrap data: `{"data": <payload>}`
- Use `$ref` for reusable schemas
- Error response shape:
  ```yaml
  ErrorResponse:
    type: object
    required: [code, message]
    properties:
      code:
        type: string
      message:
        type: string
  ```

## Handler Structure

`handler.go` implements the generated `StrictServerInterface`. Each method:
1. Extracts input from the generated request struct
2. Calls one `app.Commands.*` or `app.Queries.*` handler
3. Maps errors to HTTP responses
4. Returns the generated response type

```go
func NewHandler(application app.Application, logger *slog.Logger) http.Handler {
    h := &handler{app: application, logger: logger}
    return HandlerFromMux(NewStrictHandler(h, nil), chi.NewRouter())
}

type handler struct {
    app    app.Application
    logger *slog.Logger
}

func (h *handler) CreateItem(ctx context.Context, req CreateItemRequestObject) (CreateItemResponseObject, error) {
    result, err := h.app.Commands.ScheduleItem.Handle(ctx, command.ScheduleItemCommand{
        Name:        req.Body.Name,
        Description: req.Body.Description,
    })
    if err != nil {
        code, body := mapError(err)
        return ScheduleItemdefaultJSONResponse{StatusCode: code, Body: body}, nil
    }
    return ScheduleItem201JSONResponse{Data: toItemResponse(result)}, nil
}
```

**Zero business logic in HTTP handlers.** If you find yourself writing an `if` that isn't about request parsing or response formatting, move it to the command/query handler or domain.

## Response Mapping

Define private converter functions in `handler.go` to map domain types to generated API types:

```go
func toItemResponse(i *item.Item) Item {
    resp := Item{
        Id:        i.ID,
        Name:      i.Name,
        CreatedAt: i.CreatedAt,
        UpdatedAt: i.UpdatedAt,
    }
    if i.Description.IsSet() {
        v := i.Description.MustGet()
        resp.Description = &v
    }
    return resp
}
```

## What NOT to Do

```go
// Never edit openapi.gen.go — go generate will overwrite it
// Never put business logic in handlers — move it to command/query handlers
// Never call the repository directly from a handler — go through app layer
```

## Adding a New Endpoint — Checklist

1. Add path and operation to `openapi.yaml`
2. Run `go generate ./internal/ports/openapi/`
3. Implement the new method on `handler` in `handler.go`
4. Add the corresponding command or query handler in `internal/app/`
5. Wire the new handler in `internal/service/application.go`