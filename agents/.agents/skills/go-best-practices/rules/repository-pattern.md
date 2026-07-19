for re# Go Repository Pattern

Repository pattern for separating domain logic from database implementation in Go services.

## When to Apply

- Implementing or refactoring database access code
- Creating repository interfaces or implementations
- Adding transaction handling to data access methods
- Building in-memory repositories for tests or prototyping

## Core Rules

### 1. Define the Repository Interface in the Domain Package

The interface lives next to the domain type it serves. This follows Go's implicit interface pattern.

```go
// internal/domain/item/repository.go
package item

import (
    "context"
    "github.com/google/uuid"
)

type Repository interface {
    Create(ctx context.Context, item *Item) error
    FindByID(ctx context.Context, id uuid.UUID) (*Item, error)
    List(ctx context.Context, limit, offset int) ([]*Item, error)
    Update(ctx context.Context, id uuid.UUID, updateFn func(*Item) error) error
    Delete(ctx context.Context, id uuid.UUID) error
}
```

For repositories with authorization requirements, include a `User` parameter (see `security-by-design.md`).

### 2. Separate Database Model from Domain Model

Never add `gorm:` tags to domain types. Create a private model struct in the adapter and marshal between them explicitly.

```go
// internal/adapters/psql/item_repository.go
package psql

// private — never exported outside the adapter
type itemModel struct {
    ID          uuid.UUID `gorm:"type:uuid;primaryKey"`
    Name        string    `gorm:"not null"`
    Description *string
    CreatedAt   time.Time
    UpdatedAt   time.Time
}

func (itemModel) TableName() string { return "items" }

func toItem(m itemModel) *item.Item {
    return &item.Item{
        ID:          m.ID,
        Name:        m.Name,
        Description: m.Description,  // *string → *string, direct copy
        CreatedAt:   m.CreatedAt,
        UpdatedAt:   m.UpdatedAt,
    }
}

func toItemModel(i *item.Item) itemModel {
    return itemModel{
        ID:          i.ID,
        Name:        i.Name,
        Description: i.Description,  // *string → *string, direct copy
        CreatedAt:   i.CreatedAt,
        UpdatedAt:   i.UpdatedAt,
    }
}
```

### 3. GORM Repository Implementation

```go
type ItemRepository struct {
    DB *gorm.DB
}

func (r ItemRepository) FindByID(ctx context.Context, id uuid.UUID) (*item.Item, error) {
    var m itemModel
    if err := r.DB.WithContext(ctx).First(&m, "id = ?", id).Error; err != nil {
        if errors.Is(err, gorm.ErrRecordNotFound) {
            return nil, item.ErrNotFound
        }
        return nil, fmt.Errorf("find item: %w", err)
    }
    return toItem(m), nil
}

func (r ItemRepository) Create(ctx context.Context, i *item.Item) error {
    m := toItemModel(i)
    if err := r.DB.WithContext(ctx).Create(&m).Error; err != nil {
        return fmt.Errorf("create item: %w", err)
    }
    return nil
}
```

Always translate `gorm.ErrRecordNotFound` to the domain's `ErrNotFound` sentinel. Never let GORM errors escape the adapter.

### 4. In-Memory Implementation for Tests and Prototyping

Always provide an in-memory implementation. Useful for unit tests and local development without a database.

```go
type MemoryItemRepository struct {
    mu    sync.RWMutex
    items map[uuid.UUID]item.Item  // store values, not pointers
}

func NewMemoryItemRepository() *MemoryItemRepository {
    return &MemoryItemRepository{items: make(map[uuid.UUID]item.Item)}
}

func (r *MemoryItemRepository) FindByID(_ context.Context, id uuid.UUID) (*item.Item, error) {
    r.mu.RLock()
    defer r.mu.RUnlock()

    i, ok := r.items[id]
    if !ok {
        return nil, item.ErrNotFound
    }
    copy := i
    return &copy, nil
}

func (r *MemoryItemRepository) Create(_ context.Context, i *item.Item) error {
    r.mu.Lock()
    defer r.mu.Unlock()
    r.items[i.ID] = *i  // store copy, not pointer
    return nil
}
```

**Critical:** Store values (not pointers) in the map so uncommitted changes don't leak between operations.

### 5. Run All Implementations Through the Same Test Suite

```go
func TestRepository(t *testing.T) {
    repos := []struct {
        Name string
        Repo item.Repository
    }{
        {"memory", NewMemoryItemRepository()},
        {"postgres", NewPostgresItemRepository(t)},
    }

    for _, r := range repos {
        t.Run(r.Name, func(t *testing.T) {
            t.Parallel()
            testCreateAndFind(t, r.Repo)
            testFindByID_notFound(t, r.Repo)
        })
    }
}
```

This ensures your in-memory and GORM implementations behave identically.

## Domain-First Development Approach

For complex projects, spend the first sprint working only on the domain layer with the in-memory repository. Write unit tests against the domain. Defer the database decision. This lets you explore the domain deeply without infrastructure overhead.
