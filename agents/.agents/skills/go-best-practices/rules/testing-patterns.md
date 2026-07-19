# Go Testing Patterns for DDD/Clean Architecture

Testing patterns for fast, reliable, and maintainable tests across all layers of Go services.

## When to Apply

- Writing domain unit tests (entity behavior, value objects)
- Writing application-layer tests (command/query handlers with mocks)
- Writing integration tests against a real database
- Testing concurrent access and transaction rollback behavior

For detailed integration test examples (transactions, concurrency, Docker DB): see `testing-integration.md`.

## Test Layers Overview

| Type        | Uses Docker DB | Mocks External Services | Tests Business Logic | Speed    |
|-------------|---------------|------------------------|---------------------|----------|
| Unit        | No            | Most dependencies      | Domain + App logic  | < 1s     |
| Integration | Yes           | Usually none           | DB repositories     | < 10s    |
| Component   | Yes           | External services only | Full service flow   | < 30s    |
| End-to-end  | Yes           | None                   | Cross-service flow  | < 60s    |

## 1. Domain Unit Tests

Domain tests are the simplest -- no mocks, no infrastructure, pure logic. Aim for high coverage here.

**Always use black-box testing** (`_test` package suffix):

```go
package hour_test  // NOT package hour

func TestHour_ScheduleTraining(t *testing.T) {
    h, err := hour.NewAvailableHour(validTrainingHour())
    require.NoError(t, err)

    require.NoError(t, h.ScheduleTraining())

    assert.True(t, h.HasTrainingScheduled())
    assert.False(t, h.IsAvailable())
}

func TestHour_ScheduleTraining_with_not_available(t *testing.T) {
    h := newNotAvailableHour(t)
    assert.Equal(t, hour.ErrHourNotAvailable, h.ScheduleTraining())
}
```

Use **table-driven tests** for checking multiple scenarios:

```go
func TestFactoryConfig_Validate(t *testing.T) {
    testCases := map[string]struct {
        Config      hour.FactoryConfig
        ExpectedErr string
    }{
        "valid": {
            Config: hour.FactoryConfig{MaxWeeksInTheFutureToSet: 10, MinUtcHour: 10, MaxUtcHour: 12},
        },
        "min_hour_after_max": {
            Config:      hour.FactoryConfig{MaxWeeksInTheFutureToSet: 10, MinUtcHour: 14, MaxUtcHour: 12},
            ExpectedErr: "MinUtcHour must be less than or equal to MaxUtcHour",
        },
    }
    for name, tc := range testCases {
        t.Run(name, func(t *testing.T) {
            err := tc.Config.Validate()
            if tc.ExpectedErr != "" {
                assert.EqualError(t, err, tc.ExpectedErr)
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```

## 2. Application Layer (Command) Unit Tests

Mock dependencies with simple structs -- no mocking libraries needed if interfaces are small.

```go
package command_test

type repositoryMock struct {
    Trainings map[string]training.Training
}

func (r *repositoryMock) UpdateTraining(
    ctx context.Context, trainingUUID string, user training.User,
    updateFn func(ctx context.Context, tr *training.Training) (*training.Training, error),
) error {
    tr, ok := r.Trainings[trainingUUID]
    if !ok {
        return training.NotFoundError{TrainingUUID: trainingUUID}
    }
    updated, err := updateFn(ctx, &tr)
    if err != nil {
        return err
    }
    r.Trainings[trainingUUID] = *updated
    return nil
}
```

Use a `dependencies` helper struct to wire all mocks + the handler, then write table-driven tests.

## 3. Integration Tests (Repository)

Test that your repository works correctly with a real database. Run all DB implementations through the **same test suite**. See `testing-integration.md` for full examples.

```go
func TestRepository(t *testing.T) {
    repositories := createRepositories(t)
    for _, r := range repositories {
        t.Run(r.Name, func(t *testing.T) {
            t.Parallel()
            t.Run("testUpdateHour", func(t *testing.T) {
                t.Parallel()
                testUpdateHour(t, r.Repository)
            })
        })
    }
}
```

## Key Testing Rules

- **Always** `t.Parallel()` — tests must not depend on shared mutable state
- **Unique data per test** — no cleanup needed, no shared fixtures
- **Never** `time.Sleep` — use `assert.Eventually` or `sync.WaitGroup`
- **`require` for errors, `assert` for values** — `require` stops on failure, `assert` continues
- **Test sabotage** — break the implementation intentionally; if tests still pass, they're not testing what you think
- **Disable test cache** for integration tests: `go test -count=1 ./...`

### Test helper pattern

```go
func assertHourInRepository(ctx context.Context, t *testing.T, repo hour.Repository, h *hour.Hour) {
    t.Helper()
    require.NotNil(t, h)
    hourFromRepo, err := repo.GetOrCreateHour(ctx, h.Time())
    require.NoError(t, err)
    assert.Equal(t, h, hourFromRepo)
}
```

### Complex struct comparison with `go-cmp`

```go
cmpOpts := []cmp.Option{
    cmp.AllowUnexported(training.Training{}, training.UserType{}, time.Time{}),
}
assert.True(t, cmp.Equal(tr1, tr2, cmpOpts...), cmp.Diff(tr1, tr2, cmpOpts...))
```

## When NOT to Apply

- Prototyping or throwaway code
- Generated code (`openapi.gen.go`) — test via the handler, not the generated stubs
