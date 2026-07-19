# Integration Testing: Transactions & Concurrency

Detailed examples for testing repository implementations against a real database.

## When to Apply

- Testing GORM repository implementations with a Docker Postgres instance
- Verifying transaction rollback behavior
- Testing concurrent access / optimistic locking

## Test Transactions (Rollback)

```go
func testUpdateHour_rollback(t *testing.T, repository hour.Repository) {
    t.Helper()
    ctx := context.Background()
    hourTime := newValidHourTime()

    // First: set to available
    err := repository.UpdateHour(ctx, hourTime, func(h *hour.Hour) (*hour.Hour, error) {
        require.NoError(t, h.MakeAvailable())
        return h, nil
    })
    require.NoError(t, err)

    // Second: try to change, but return error (should rollback)
    err = repository.UpdateHour(ctx, hourTime, func(h *hour.Hour) (*hour.Hour, error) {
        require.NoError(t, h.MakeNotAvailable())
        return h, errors.New("something went wrong")
    })
    require.Error(t, err)

    // Verify: still available (rollback worked)
    persistedHour, err := repository.GetOrCreateHour(ctx, hourTime)
    require.NoError(t, err)
    assert.True(t, persistedHour.IsAvailable(), "change was persisted, not rolled back")
}
```

## Test Concurrent Access (Optimistic Locking)

```go
func testUpdateHour_parallel(t *testing.T, repository hour.Repository) {
    ctx := context.Background()
    hourTime := newValidHourTime()

    // Make hour available first
    _ = repository.UpdateHour(ctx, hourTime, func(h *hour.Hour) (*hour.Hour, error) {
        _ = h.MakeAvailable()
        return h, nil
    })

    workersCount := 20
    workersDone := sync.WaitGroup{}
    workersDone.Add(workersCount)
    startWorkers := make(chan struct{})
    trainingsScheduled := make(chan int, workersCount)

    for worker := 0; worker < workersCount; worker++ {
        w := worker
        go func() {
            defer workersDone.Done()
            <-startWorkers

            schedulingTraining := false
            err := repository.UpdateHour(ctx, hourTime, func(h *hour.Hour) (*hour.Hour, error) {
                if h.HasTrainingScheduled() {
                    return h, nil
                }
                if err := h.ScheduleTraining(); err != nil {
                    return nil, err
                }
                schedulingTraining = true
                return h, nil
            })
            if schedulingTraining && err == nil {
                trainingsScheduled <- w
            }
        }()
    }

    close(startWorkers)
    workersDone.Wait()
    close(trainingsScheduled)

    var scheduled []int
    for w := range trainingsScheduled {
        scheduled = append(scheduled, w)
    }
    assert.Len(t, scheduled, 1, "only one worker should schedule training")
}
```

## Unique Test Data Helper

Avoid shared fixtures — generate unique data per test so tests don't interfere with each other and no cleanup is needed.

```go
var usedHours = sync.Map{}

func newValidHourTime() time.Time {
    for {
        t := randomFutureHour()
        _, alreadyUsed := usedHours.LoadOrStore(t.Unix(), true)
        if !alreadyUsed {
            return t
        }
    }
}
```

## When NOT to Apply

- Domain-only tests that don't touch a database — use plain unit tests instead
- Tests for external service clients — mock the HTTP calls, don't hit real services
