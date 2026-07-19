# Go Monetary Amounts (Precision-Safe Money)

Precision-safe representation of monetary amounts — fiat and crypto — across Postgres, GORM, the domain, and wire formats.

Money is tricky, and crypto makes it trickier. ETH has 18 decimal places; one ETH expressed in its smallest unit (wei) is 10¹⁸ — already a meaningful fraction of int64's ~9.22×10¹⁸ ceiling, and any wallet over ~9.2 ETH-in-wei overflows. Floats can't exactly represent 0.1. The only correct representation across the stack is **arbitrary-precision decimal**, stored as Postgres `NUMERIC(38, 18)` and carried in Go as `github.com/shopspring/decimal`.

## When to Apply

- Designing schemas, columns, or Go types that store monetary amounts (balance, transaction, ledger, fee, payout, deposit, withdrawal)
- Modelling a Wallet, Account, or any domain entity that holds value
- Migrating legacy `BIGINT` / `amount_cents` / `amount_subunits` columns to a precision-safe representation
- Designing gRPC, REST, or Kafka payloads that carry amounts
- Reviewing Postgres DDL or GORM models that touch money

## The Pattern (TL;DR)

| Layer | Type |
|---|---|
| Postgres column | `NUMERIC(38, 18)` |
| GORM field (NOT NULL) | `decimal.Decimal` |
| GORM field (nullable) | `*decimal.Decimal` |
| Domain field (NOT NULL) | `decimal.Decimal` |
| Domain field (nullable) | `*decimal.Decimal` |
| Command/query input (optional) | `*decimal.Decimal` |
| gRPC / REST / Kafka | `string`, parsed via `decimal.NewFromString`, emitted via `.String()` |
| Tests | `decimal.RequireFromString("1.23")` |

`shopspring/decimal` implements `database/sql` `Scanner` and `Valuer`, plays nicely with `gorm.io/gen`, and ships JSON marshalling — the integration is mostly free. Allowed in the domain layer because it's a value-object library, same category as `uuid` (see `project-structure.md`).

## Core Rules

### 1. Use `NUMERIC(38, 18)` for All Monetary Columns

38 total digits, 18 after the decimal — i.e., 20 integer digits and 18 fractional. Covers ETH (10⁻¹⁸ wei), BTC (10⁻⁸ satoshi), USDT (10⁻⁶), USD (10⁻²), and aggregate balances up to ~10²⁰. Standardize on `(38, 18)` once and you're done.

Bad:
```sql
CREATE TABLE wallets (
    balance BIGINT NOT NULL DEFAULT 0  -- overflows past 9.2 ETH expressed as wei
);
```

```sql
CREATE TABLE wallets (
    balance DOUBLE PRECISION NOT NULL  -- IEEE 754, can't represent 0.1 exactly
);
```

Good:
```sql
CREATE TABLE wallets (
    id              UUID PRIMARY KEY,
    user_id         UUID            NOT NULL,
    currency        TEXT            NOT NULL,
    balance         NUMERIC(38, 18) NOT NULL DEFAULT 0,
    pending_credit  NUMERIC(38, 18),
    created_at      TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    CHECK (balance >= 0)
);
```

Conventions:
- `NOT NULL DEFAULT 0` for balances and totals. `NULL` should mean "unknown / not yet computed", not zero.
- Nullable `NUMERIC(38, 18)` only for amounts that legitimately don't exist yet (e.g., `balance_after` on an unsettled transaction).
- Add `CHECK (col >= 0)` for columns that must be non-negative — Postgres enforces it for free.

### 2. GORM Models Use `decimal.Decimal` and `*decimal.Decimal`

Use `decimal.Decimal` for NOT NULL columns. For nullable columns, use `*decimal.Decimal` — **not** `decimal.NullDecimal`. This matches the project-wide `*T` pointer convention for nullables (see `errors-and-nullables.md`); a parallel `{Decimal, Valid}` representation defeats the convention and forces every reader to remember which library used which shape.

```go
import "github.com/shopspring/decimal"

// internal/adapters/psql/wallet_repository.go
type walletModel struct {
    ID            uuid.UUID        `gorm:"column:id;type:uuid;primaryKey"`
    UserID        uuid.UUID        `gorm:"column:user_id;type:uuid;not null"`
    Currency      string           `gorm:"column:currency;type:text;not null"`
    Balance       decimal.Decimal  `gorm:"column:balance;type:numeric(38,18);not null"`
    PendingCredit *decimal.Decimal `gorm:"column:pending_credit;type:numeric(38,18)"`
}

func (walletModel) TableName() string { return "wallets" }
```

The `type:numeric(38,18)` tag is what `gorm.io/gen` emits when the column is `NUMERIC(38, 18)` — declare the column type correctly in SQL and re-run codegen; the field types come out right.

### 3. Domain Types Use the Same Decimal Types

Don't translate amount types at the repository boundary. Translation layers are where precision goes to die. Domain fields use `decimal.Decimal` (or `*decimal.Decimal` for optional) — the converter to/from the GORM model is a direct field copy.

```go
// internal/domain/wallet/wallet.go
package wallet

import (
    "github.com/google/uuid"
    "github.com/shopspring/decimal"
)

type Wallet struct {
    ID            uuid.UUID
    UserID        uuid.UUID
    Currency      string
    Balance       decimal.Decimal
    PendingCredit *decimal.Decimal
}

type Adjustment struct {
    SourceID uuid.UUID
    Amount   decimal.Decimal // negative for debits, positive for credits
}
```

Operate on amounts via decimal's methods — Go arithmetic operators don't compile on `decimal.Decimal`, and "just convert to float for one calculation" is the thing you're trying to prevent.

```go
balanceAfter := balanceBefore.Add(adj.Amount)
remaining    := balance.Sub(bet)

if balance.LessThan(bet) { /* insufficient funds */ }
if amount.IsZero()       { /* no-op */ }

fee := amount.Mul(decimal.RequireFromString("0.05")).RoundBank(8)
```

Don't keep a parallel `int64` field "for fast comparisons" or "for the cache key". Either decimal is the truth everywhere, or you've created two sources that will drift.

### 4. Wire Boundaries Carry Amounts as Strings

When amounts cross a process boundary (gRPC, REST/JSON, Kafka, Redis), serialize them as **strings**. Parse with `decimal.NewFromString`, emit with `.String()`.

Bad — int64 on the wire reintroduces the original overflow problem:
```protobuf
message CreateAdjustmentRequest {
    int64 amount_wei = 1;  // overflows for any non-trivial ETH amount
}
```

Good:
```protobuf
message CreateAdjustmentRequest {
    string amount = 1;  // decimal number, optional sign, optional fractional part
}
```

```go
// Outbound
req := &walletpb.CreateAdjustmentRequest{
    Amount: adj.Amount.String(),
}

// Inbound
amt, err := decimal.NewFromString(req.GetAmount())
if err != nil {
    return fmt.Errorf("parse amount %q: %w", req.GetAmount(), err)
}
```

For OpenAPI with `oapi-codegen`, alias the schema to `decimal.Decimal` so the generated Go type is convenient:

```yaml
components:
  schemas:
    MoneyAmount:
      type: string
      pattern: ^-?\d+(\.\d+)?$
      x-go-type: decimal.Decimal
      x-go-type-import:
        path: github.com/shopspring/decimal
```

JSON numbers lose precision the moment a JS client deserializes them into a `double`. Strings are exact, language-agnostic, and round-trip cleanly across any decimal library.

### 5. Migrating from BIGINT to NUMERIC(38, 18)

The shape depends on what the BIGINT held.

**Case A — BIGINT held units already** (e.g., USD stored as 100, no scaling):
```sql
-- up
ALTER TABLE wallets ALTER COLUMN balance TYPE NUMERIC(38, 18);

-- down
ALTER TABLE wallets ALTER COLUMN balance TYPE BIGINT USING balance::bigint;
```

**Case B — BIGINT held subunits** (cents, satoshis, wei). Divide by `10^decimals`:
```sql
-- single-currency table (e.g., always USD with 2 decimals)
ALTER TABLE transactions
    ALTER COLUMN amount TYPE NUMERIC(38, 18) USING amount::numeric / 100;

-- mixed currencies
ALTER TABLE transactions
    ALTER COLUMN amount TYPE NUMERIC(38, 18) USING (
        amount::numeric / power(10, CASE currency
            WHEN 'BTC' THEN 8
            WHEN 'ETH' THEN 18
            WHEN 'USDT' THEN 6
            WHEN 'USD' THEN 2
            ELSE 0
        END)
    );
```

Migration checklist:
1. Update the Postgres column type.
2. Regenerate GORM models (`gorm.io/gen` or hand-edit) so fields are `decimal.Decimal` / `*decimal.Decimal`.
3. Update domain types and remove all int64/subunit conversions in the domain layer.
4. **Audit every wire boundary** — gRPC, REST, OpenAPI, Kafka, admin endpoints, CSV exports, internal reporting. Anywhere amounts are still int64 is a precision leak that survived the migration.
5. Update tests to use `decimal.RequireFromString`.
6. For Case B the `down` migration loses precision — document this in the migration file or omit it.
7. Rename misleading legacy columns (`amount_cents` → `amount`) in the same migration. After the migration the column no longer holds cents.

### 6. Test with `decimal.RequireFromString` and `.Equal`

Don't use float literals in tests — they lie. Compare with `.Equal`, never `==` (`"1.0"` and `"1.00"` are equal in value but differ in internal exponent).

```go
import "github.com/shopspring/decimal"

func TestApplyAdjustment(t *testing.T) {
    balance := decimal.RequireFromString("1.234567890123456789")
    adj     := decimal.RequireFromString("-0.000000000000000001")

    got  := balance.Add(adj)
    want := decimal.RequireFromString("1.234567890123456788")

    if !got.Equal(want) {
        t.Fatalf("got %s, want %s", got, want)
    }
}
```

Helpers for terse fixtures:
```go
func dec(s string) decimal.Decimal { return decimal.RequireFromString(s) }
```

## Common Pitfalls

1. **Misleading legacy column names.** A column called `amount_cents` after migration no longer holds cents. Rename it (`amount`) in the same migration, or future readers will build the wrong mental model.
2. **int64 leaks at admin / reporting endpoints.** The user-facing path migrates cleanly, but admin dashboards, CSV exports, and internal APIs often still expose int64 "for convenience". Audit every wire format.
3. **`IntPart()` on subunit conversions.** `amount.Mul(pow10(decimals)).IntPart()` to "convert to wei" silently overflows int64 for non-trivial ETH amounts (`IntPart()` returns int64 — values that don't fit are truncated without error). If you must produce subunits, return `*big.Int` (`.BigInt()` / `.Coefficient()`) or a string. Never `int64`.
4. **Float anywhere in the chain.** Including "just for the percentage". Use `amount.Mul(decimal.RequireFromString("0.05")).RoundBank(n)`. Prefer `RequireFromString` over `NewFromFloat` to avoid the float literal step entirely.
5. **JSON numbers instead of strings.** `json.Marshal(decimal.Decimal)` emits a JSON number by default; JS clients lose precision the moment they hit `JSON.parse`. Configure the library or wrap with a custom `MarshalJSON` that quotes the value.
6. **Rounding before storage.** Don't pre-round to 2 decimals "because it's USD" — store the full precision you receive. Round only at the presentation/provider boundary that demands it (`RoundBank` is banker's rounding — symmetric, the right default for money).
7. **Using `decimal.NullDecimal` for nullable fields.** Use `*decimal.Decimal` instead — see Rule 2. Domain coherence beats one library's idiom.

## Review Checklist

- [ ] Postgres column is `NUMERIC(38, 18)` (or another deliberate `(p, s)` justified by the use case)
- [ ] No `BIGINT` / `INTEGER` / `DOUBLE PRECISION` columns for amounts
- [ ] GORM fields are `decimal.Decimal` (NOT NULL) or `*decimal.Decimal` (nullable) — never `decimal.NullDecimal`
- [ ] Domain types use the same decimal types — no parallel int64 fields
- [ ] All wire formats (gRPC, REST, Kafka) carry amounts as strings
- [ ] No `.IntPart()` on amounts unless wrapped to detect overflow
- [ ] No `float32` / `float64` anywhere in the money path
- [ ] No misleading column names like `amount_cents` after migration
- [ ] Tests use `decimal.RequireFromString`, compare with `.Equal`
- [ ] Rounding happens at the provider boundary, not at storage

## When NOT to Apply

- Counters that aren't money (page views, request counts) — `BIGINT` / `int64` is correct.
- Identifiers (user IDs, sequence numbers) — never `decimal`.
- Performance-critical hot paths where the amount is bounded and known to fit in `int64` (e.g., a per-request rate-limit counter measured in microcredits) — document the bound.

## Reference

`shopspring/decimal` API: <https://github.com/shopspring/decimal>. The methods you'll reach for: `NewFromString`, `RequireFromString`, `Zero`, `NewFromInt`, `Add`, `Sub`, `Mul`, `Div`, `Neg`, `Equal`, `LessThan`, `GreaterThan`, `Cmp`, `IsZero`, `RoundBank`, `Truncate`, `String`, `BigInt`.
