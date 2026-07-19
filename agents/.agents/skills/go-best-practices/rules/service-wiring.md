# Service Wiring

Configuration, database, migrations, and graceful shutdown patterns for purposeinplay Go services.

## When to Apply

- Setting up a new service
- Adding a new dependency (external service, new DB client)
- Modifying startup or shutdown sequence
- Adding config values

---

## Config: caarlos0/env

Config lives in `internal/service/config.go`. Uses [`github.com/caarlos0/env`](https://github.com/caarlos0/env) — struct tags declare env var names and defaults, no YAML file, no Viper.

```go
import "github.com/caarlos0/env/v11"

type Config struct {
    Server ServerConfig
    DB     DBConfig
}

type ServerConfig struct {
    Address string `env:"SERVER_ADDRESS" envDefault:":8080"`
}

type DBConfig struct {
    Host     string `env:"DB_HOST"     envDefault:"localhost"`
    Port     string `env:"DB_PORT"     envDefault:"5432"`
    User     string `env:"DB_USER"     envDefault:"postgres"`
    Password string `env:"DB_PASSWORD" envDefault:"postgres"`
    Name     string `env:"DB_NAME"     envDefault:"app"`
    SSLMode  string `env:"DB_SSLMODE"  envDefault:"disable"`
}

func LoadConfig() (Config, error) {
    var cfg Config
    if err := env.Parse(&cfg); err != nil {
        return Config{}, fmt.Errorf("parse env: %w", err)
    }
    return cfg, nil
}
```

Mark required values with `env:"...,required"`. Use `envDefault` for sensible local defaults. Do not introduce a YAML config file or `--config` flag.

---

## Database: GORM + Exponential Backoff

DB connection with retry in `internal/adapters/psql/client.go`:

```go
func Connect(dsn string) (*gorm.DB, error) {
    var db *gorm.DB
    err := backoff.Retry(func() error {
        var err error
        db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
        return err
    }, backoff.NewExponentialBackOff())
    if err != nil {
        return nil, fmt.Errorf("connect to postgres: %w", err)
    }
    return db, nil
}
```

DSN construction in `internal/adapters/psql/dsn.go`:
```go
func ComposeDSN(host, port, user, password, dbName, sslMode string) string {
    return fmt.Sprintf(
        "host=%s port=%s user=%s password=%s dbname=%s sslmode=%s",
        host, port, user, password, dbName, sslMode,
    )
}
```

---

## Migrations: golang-migrate

SQL files in `sql/migrations/`, naming: `<N>_<description>.{up,down}.sql`.

---

## Application Wiring: internal/service/application.go

The **only** place where concrete adapters are constructed and injected:

```go
func NewApplication(db *gorm.DB, logger *slog.Logger) app.Application {
    itemRepo := psql.ItemRepository{DB: db}

    return app.Application{
        Commands: app.Commands{
            CreateItem: command.NewCreateItemHandler(logger, itemRepo),
            UpdateItem: command.NewUpdateItemHandler(logger, itemRepo),
            DeleteItem: command.NewDeleteItemHandler(logger, itemRepo),
        },
        Queries: app.Queries{
            GetItem:   query.NewGetItemHandler(logger, itemRepo),
            ListItems: query.NewListItemsHandler(logger, itemRepo),
        },
    }
}
```

When adding a new aggregate: instantiate its GORM repository here, pass it to the handler constructors, add handlers to `Commands`/`Queries`.

---

## Server Startup: cmd/server.go

Use `signal.NotifyContext` — one signal handler only. **Do not** add a second `signal.Notify` or `signalChan`.

```go
func runServer(cmd *cobra.Command, _ []string) error {
    ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
    defer stop()

    cfg, err := service.LoadConfig()
    if err != nil {
        return fmt.Errorf("load config: %w", err)
    }

    db, err := psql.Connect(psql.ComposeDSN(
        cfg.DB.Host, cfg.DB.Port, cfg.DB.User,
        cfg.DB.Password, cfg.DB.Name, cfg.DB.SSLMode,
    ))
    if err != nil {
        return fmt.Errorf("connect db: %w", err)
    }

    application := service.NewApplication(db, logger)
    handler := openapi.NewHandler(application, logger)

    srv := httpserver.New(cfg.Server.Address, handler)
    go srv.Start()

    <-ctx.Done()

    return srv.Stop(context.Background())
}
```

Use `github.com/purposeinplay/go-commons/httpserver` — do not implement your own graceful shutdown.