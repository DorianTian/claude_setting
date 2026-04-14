---
name: code-standards
description: "Industry-standard code conventions & quality rules. Covers: naming, variables, operators, function design, file organization, comments, error handling, type safety, logging, React, testing, security, performance, Git. Languages: TypeScript/JavaScript, Go, Python, SQL, Shell/Bash. Sources: Google Style Guides, Airbnb JS, Effective Go, PEP 8, OWASP, Conventional Commits. Load via /code-standards before writing code or during code review. 代码规范、编码标准、命名规范、代码质量"
user-invocable: true
---

# Code Standards — Industry Reference

Actionable, enforceable rules from authoritative style guides. Every rule is specific enough to be machine-enforced.

**Sources**: Google Style Guides (TS/Go/Python/Shell), Airbnb JS, Effective Go, PEP 8/257/484, OWASP, Conventional Commits, Clean Code, Go Code Review Comments, Uber Go

**Languages**: TypeScript/JavaScript, Go, Python, SQL, Shell/Bash

## Arguments

$ARGUMENTS

If no arguments provided, apply the FULL ruleset as context for the current task. If arguments specify a category (e.g., "naming", "testing"), focus on that section.

---

## 1. Naming Conventions

### General Principles

| Rule | Source |
|------|--------|
| Names must be descriptive; single-letter only for `i/j/k` (loops), `T` (generics), `_` (unused) | Airbnb, Google, PEP 8 |
| Booleans: prefix with `is`, `has`, `can`, `should`, `will` | Airbnb, convention |
| No negated booleans (`isNotReady` -> `isReady`) | Clean Code |
| Acronyms: all-caps or all-lower in TS/JS (`HTTPRequest` or `httpRequest`); all-caps exported in Go (`ID`, `URL`) | Airbnb, Effective Go |

### Language-Specific

| Element | TS/JS | Go | Python | SQL | Shell |
|---------|-------|-----|--------|-----|-------|
| Variables | `camelCase` | `camelCase`/`PascalCase` (visibility) | `snake_case` | `snake_case` | `snake_case` |
| Functions | `camelCase` | `camelCase`/`PascalCase` | `snake_case` | `snake_case` | `snake_case` |
| Classes/Types | `PascalCase` | `PascalCase` | `PascalCase` | N/A | N/A |
| Interfaces | `PascalCase` (no `I` prefix) | `PascalCase` (`-er` suffix for single-method) | `PascalCase` | N/A | N/A |
| Constants | `UPPER_SNAKE` (exported), `camelCase` (local) | `PascalCase`/`camelCase` | `UPPER_SNAKE` | `UPPER_SNAKE` | `UPPER_SNAKE` |
| Enums | `PascalCase` name, `CONSTANT_CASE` members | N/A (const blocks) | `PascalCase`/`UPPER_SNAKE` | N/A | N/A |
| Files | `kebab-case.ts`, `PascalCase.tsx` (components) | `snake_case.go` | `snake_case.py` | `snake_case.sql` | `kebab-case.sh` |
| Directories | `kebab-case` | `lowercase` (single word) | `snake_case` | N/A | `kebab-case` |
| Tests | `*.test.ts` / `*.spec.ts` | `*_test.go` | `test_*.py` | N/A | `*_test.sh` |
| Private | `private` keyword / `#field` | lowercase first letter | `_single_leading_underscore` | N/A | N/A |

### Key Rules

- **TS**: No `I` prefix on interfaces. No default exports — use named exports. (Google TS)
- **Go**: Package names lowercase single word, no underscores. MixedCaps, not underscores. (Effective Go)
- **Go**: Method receivers: 1-2 letter abbreviation of type name. Never `self`/`this`/`me`. Consistent across all methods. (Go Code Review Comments)
- **Go**: Don't repeat package name in identifiers (`chubby.File` not `chubby.ChubbyFile`). Avoid `util`/`common`/`misc`/`types` package names. (Go Code Review Comments)
- **Go**: **No `Get` prefix on getters** — field `owner` -> getter `Owner()`, setter `SetOwner()`. (Effective Go)
- **Go**: Variable name length ~ scope: short names for small scope (`i`, `r`, `c`), longer for larger scope. (Go Code Review Comments)
- **Go**: Constants: never `ALL_CAPS`. Exported: `MaxPacketSize`. Unexported: `maxPacketSize`. (Google Go Decisions)
- **Go**: Error variables: `ErrNotFound`; error types: `QueryError` (suffix `Error`). (Uber Go)
- **Python**: `__dunder__` names reserved for system use. Module constants `UPPER_SNAKE`. (PEP 8)
- **SQL**: Tables plural `snake_case`, columns singular `snake_case`, keywords `UPPERCASE`. Indexes: `idx_{table}_{columns}`, unique: `uniq_{table}_{columns}`. (Holywell, DBA convention)
- **Shell**: Constants `UPPER_SNAKE` with `readonly`. Local variables `lower_snake` with `local`. Namespace functions `pkg::func()`. (Google Shell)

---

## 2. Variable Declaration

### TypeScript/JavaScript (Airbnb, Google TS)

| Rule | Source |
|------|--------|
| `const` by default; `let` only when reassignment needed; **never `var`** | Airbnb 2.1-2.2 |
| One variable per declaration | Airbnb 13.2 |
| Group `const` first, then `let` | Airbnb 13.3 |
| Declare where first used, not at top of function | Airbnb 13.4 |
| No chain assignments (`a = b = c = 1`) | Airbnb 13.5 |
| No `export let` — mutable exports forbidden | Google TS |
| Use object/array destructuring for multiple properties | Airbnb 5.1-5.3 |
| Object destructuring for multi-return values | Airbnb 5.3 |
| **No variable shadowing** — don't redeclare names from outer scopes | ESLint `no-shadow` |
| Declare before use — no temporal dead zone issues | ESLint `no-use-before-define` |

### Magic Numbers & Strings

| Rule | Source |
|------|--------|
| **No magic numbers** — extract to named constants. Exceptions: `0`, `1`, `-1`, array indices | ESLint `no-magic-numbers` |
| **No magic strings** — extract identifiers/statuses to named constants, enums, or union types | Industry convention |

```typescript
// Bad
if (user.role === 'admin') { ... }
if (retries > 3) { ... }

// Good
const MAX_RETRIES = 3;
type Role = 'admin' | 'viewer' | 'editor';
if (user.role === Role.ADMIN) { ... }
if (retries > MAX_RETRIES) { ... }
```

### Object & Array Patterns (Airbnb)

| Rule | Source |
|------|--------|
| Property value shorthand: `{ name }` not `{ name: name }`. Group shorthands first | Airbnb 3.4-3.5 |
| Object spread `{ ...obj }` for shallow copy (not `Object.assign`) | Airbnb 3.8 |
| Array spread `[...arr]` for array copy | Airbnb 4.3 |
| Object rest `const { a, ...rest } = obj` for property omission | Airbnb 3.8 |

### Go (Effective Go, Go Code Review Comments)

| Rule |
|------|
| `:=` for short declarations inside functions |
| `var` for package-level or when zero value is meaningful |
| Declare close to first use |
| Group related `var` in `var()` block |
| **Nil slice**: declare as `var t []string` (nil), not `t := []string{}`. Exception: `[]string{}` when encoding to JSON (nil -> `null`, empty -> `[]`) |

### Python (PEP 8, Google Python)

| Rule |
|------|
| Type annotations for function signatures and complex variables (PEP 484) |
| Module-level constants at top after imports |
| **Never** mutable default arguments (`def foo(items=[])` is a bug) — use `None` + guard |
| `_` for unused variables in unpacking |
| Walrus operator (`:=`): only in `while` loops and `if` conditions. Never in complex expressions. (PEP 572) |
| **f-strings** over `.format()` and `%` — faster and more readable. Use `!r` for debug repr. (PEP 498) |

### Shell (Google Shell)

| Rule |
|------|
| `readonly` for constants |
| `local` for function-scoped variables |
| **Always** quote expansions: `"${var}"` not `$var` (prevents word splitting/globbing) |
| Initialize variables before use |

---

## 3. Operators & Expressions

### Equality & Comparison

| Rule | Source |
|------|--------|
| **Always `===` and `!==`** — never `==` / `!=` | Airbnb 15.1 |
| **Exception**: `== null` is allowed (and recommended) to check both `null` and `undefined` simultaneously | Google TS |
| **No negated conditions when else exists**: prefer `if (a) {} else {}` over `if (!a) {} else {}` | Convention |

### Optional Chaining & Nullish Coalescing

| Rule | Source |
|------|--------|
| **Use `?.`** instead of `a && a.b && a.b.c` | typescript-eslint `prefer-optional-chain` |
| **Use `??`** instead of `\|\|` when left operand may be `0`, `''`, or `false` (falsy but valid). `??` only triggers on `null`/`undefined` | typescript-eslint `prefer-nullish-coalescing` |

```typescript
// Bad — || treats 0, '', false as falsy
const port = config.port || 3000;       // Bug if config.port is 0
const name = user?.name || 'Anonymous'; // Bug if name is ''

// Good — ?? only triggers on null/undefined
const port = config.port ?? 3000;
const name = user?.name ?? 'Anonymous';
```

### Ternaries & Templates

| Rule | Source |
|------|--------|
| **No nested ternaries** — extract to variables or use `if/else` | Airbnb 15.6, ESLint `no-nested-ternary` |
| **Template literals** over string concatenation for programmatic strings | Airbnb 6.3, Google TS |
| No line continuations in strings | Airbnb 6.2 |

### Array Methods

| Rule | Source |
|------|--------|
| Prefer `map`/`filter`/`find`/`some`/`every` over loops for transformation/search | Airbnb 11.1 |
| Use `for...of` only for side effects | Airbnb 11.1 |
| **Never `for...in` on arrays** | Airbnb 11.1 |
| Avoid `reduce` when `map` + `filter` is clearer | Convention |

---

## 4. Function Design

### Hard Limits

| Metric | Threshold | Source |
|--------|-----------|--------|
| **Max length** | 50 lines (TS/JS/Python); Go can be longer if linear | Google, Clean Code |
| **Max parameters** | 4 positional; use options object beyond that | Airbnb, Clean Code |
| **Cyclomatic complexity** | 10 per function | ESLint `complexity` |
| **Max nesting depth** | 4 levels | Google style guides |
| **Shell functions** | 50 lines; scripts 100+ lines must use functions | Google Shell |

### Universal Principles

| Rule | Source |
|------|--------|
| Single Responsibility: one thing at one abstraction level | Clean Code, SOLID |
| Early return / guard clauses: validate at top, return early | Effective Go |
| Do not mutate parameters | Airbnb 7.12 |
| Default parameters last | Airbnb 7.9 |
| Functions return consistent types (not `string | undefined | null | false`) | Google TS |
| Arrow functions for callbacks, function declarations for named functions (TS/JS) | Google TS |
| `>3` params -> options object (TS/JS), functional options (Go) | Airbnb, Google Go |
| **`async` functions must contain `await`** — don't mark functions `async` unnecessarily | ESLint `require-await` |

### Go-Specific

| Rule | Source |
|------|--------|
| Accept interfaces, return structs | Google Go |
| Use functional options for complex constructors | Google Go |
| Error return as last value | Effective Go |
| **`context.Context` must be the first parameter**. Never store in struct. `context.Background()` only at outermost boundary | Go Code Review Comments |
| **Prefer synchronous functions** — callers can add concurrency; removing it is impossible | Go Code Review Comments |
| **Avoid `init()` functions** — prefer explicit initialization from `main()`. If unavoidable: must be deterministic, no goroutines, no env state | Uber Go, Google Go |

### Shell-Specific

- `main()` function required in scripts; call `main "$@"` at end
- All function variables must use `local`

### Python-Specific

- `match/case` (3.10+) over `if/elif` chains for structural pattern matching on types/shapes/enums. Not for simple value comparisons. (PEP 634)

---

## 5. File Organization

### File Length Limits

| Language | Max Lines | Source |
|----------|----------|--------|
| TS/JS | 300-400 | Industry, ESLint `max-lines` |
| Go | No hard limit; split when responsibilities diverge | Google Go |
| Python | 500 | Google Python |
| Shell | 100+ must be structured with functions | Google Shell |

### File Structure Order

**TS/JS** (Google TS, Airbnb):
1. License header (if any)
2. Imports: external libs -> internal absolute -> relative -> side-effect -> `import type` (separate group)
3. Constants / module-level declarations
4. Type/Interface definitions
5. Implementation
6. Exports (if not inline)

**Go** (Effective Go):
1. Package clause -> Imports (stdlib, external, internal) -> Constants -> Variables -> Types -> Constructors (`New...`) -> Methods (by receiver) -> Helpers

**Python** (PEP 8):
1. Module docstring -> Imports (stdlib, third-party, local) -> `__all__`/`__version__` -> Constants -> Classes/functions -> `if __name__ == '__main__':`

**Shell** (Google Shell):
1. Shebang -> description comment -> source statements -> `readonly` constants -> globals -> functions -> `main()` -> `main "$@"`

### Import Rules

| Rule | Source |
|------|--------|
| **TS/JS**: No wildcard imports unless namespacing large APIs | Google TS |
| **TS/JS**: No default exports; use named exports | Google TS |
| **TS/JS**: Use `import type` for type-only imports | Google TS |
| **TS/JS**: Never import same path twice — consolidate | Airbnb 10.4 |
| **Go**: Use `goimports`; aliases only for name conflicts; no `.` imports | Effective Go |
| **Python**: One import per line; absolute imports preferred; no `from module import *` | PEP 8 |

### Structural Rules

| Rule | Source |
|------|--------|
| **No barrel files** (`index.ts` re-exports) — cause circular deps, break tree-shaking, slow tooling. Import directly from source module | Google TS (implicit), industry consensus |
| **No circular imports** — use `dependency-cruiser` or `madge` to detect. Fix: extract shared types, use DI, restructure graph. Run in CI | Industry convention |
| **Migration file naming**: timestamp prefix `20260329120000_add_users_table.sql`. Timestamps avoid merge conflicts. One migration per logical change | Flyway/Liquibase convention |

---

## 6. Comments & Documentation

### When to Comment

| Rule | Source |
|------|--------|
| Code is self-documenting; comments explain **why**, not **what** | Clean Code, all guides |
| `TODO:` for planned improvements (with owner/ticket); `FIXME:` for known issues | Airbnb 18.5-18.6 |
| `HACK:` / `WORKAROUND:` for non-ideal solutions with explanation | Convention |
| **Delete** commented-out code (VCS has history) | All guides |
| No section-separator banner comments | Google TS |
| Comment non-obvious algorithms, business rules, workarounds | Universal |

### Documentation Standards

**TS/JS** — JSDoc on all exported functions/classes/interfaces:
```typescript
/**
 * Resolves user display name from multiple sources.
 * Falls back to email prefix if no explicit name set.
 *
 * @param userId - Unique user identifier
 * @returns Resolved display name
 * @throws {NotFoundError} If user does not exist
 */
```

**Go** — GoDoc: comment starts with the name, complete sentences:
```go
// ParseSize parses a human-readable size string (e.g., "10KB") into bytes.
// It returns an error if the format is unrecognized.
func ParseSize(s string) (int64, error) { ... }
```

**Python** — Google-style docstrings with `Args:`, `Returns:`, `Raises:`:
```python
def fetch_rows(table_name: str, limit: int = 100) -> list[dict]:
    """Fetches rows from the given table.

    Args:
        table_name: The name of the table to query.
        limit: Maximum number of rows to return.

    Returns:
        A list of dicts mapping column names to values.

    Raises:
        ConnectionError: If the database is unreachable.
    """
```

**SQL** — Comment above each major section explaining business logic; inline for non-obvious JOINs/WHEREs.

**Shell** — Every function: what it does, globals used/modified, arguments, return values (Google Shell).

---

## 7. Error Handling

### TypeScript/JavaScript

| Rule | Source |
|------|--------|
| Throw `Error` objects (or subclasses), never strings/plain objects | Google TS, `only-throw-error` |
| Custom error classes for domain errors | Convention |
| `catch (error: unknown)` + `instanceof` narrowing; also in `.catch(err => ...)` callbacks | TS 4.4+, Google TS |
| Handle at boundary layers (middleware); use `throw` internally | Node.js convention |
| `async/await` + `try/catch`, not `.then().catch()` chains | Convention |
| Never silently swallow errors (empty catch) | All guides |
| Error messages: include what failed, why, and context | Google SRE |
| **`return await` in try/catch** — ensures errors are caught locally. Outside try/catch, don't add unnecessary `await` before return | typescript-eslint `return-await` |

### Promise Patterns

| Rule | Source |
|------|--------|
| **`Promise.all()`** for independent concurrent operations — don't sequential `await` when unnecessary | MDN, async best practices |
| **`Promise.allSettled()`** when individual failures should not abort the batch | MDN |
| **No `await` in loops** when iterations are independent — collect promises, then `Promise.all()` | ESLint `no-await-in-loop` |
| **No floating promises** — every Promise must be `await`ed, returned, `.then()/.catch()`'d, or `void`'d | typescript-eslint `no-floating-promises` |
| **No misused promises** — don't pass async functions where sync callbacks expected (e.g., `arr.forEach(async ...)`) | typescript-eslint `no-misused-promises` |

### Go

| Rule | Source |
|------|--------|
| **Always** check returned errors — never `_` discard unless justified | Effective Go |
| Wrap with context: `fmt.Errorf("fetch user %s: %w", id, err)` | Go 1.13+ |
| Sentinel errors for expected conditions: `var ErrNotFound = errors.New(...)` | Effective Go |
| Check with `errors.Is()` / `errors.As()`, not `==` | Go 1.13+ |
| No `panic` for normal errors; only truly unrecoverable | Effective Go |
| Error strings: lowercase, no trailing punctuation | Effective Go |
| **No in-band error values** — don't return `-1`, `""`, `nil` to signal errors. Use `(value, error)` or `(value, bool)` | Go Code Review Comments |
| **`errors.Join(err1, err2)`** (Go 1.20+) to combine multiple errors. Useful in cleanup/deferred paths | Go stdlib |
| **Handle errors once** — don't log AND return the same error (causes duplicate reports). Pick one | Uber Go |
| **Deferred error handling**: `defer func() { closeErr := f.Close(); if err == nil { err = closeErr } }()` for named returns | Google Go |
| **`Must` prefix**: functions that panic on error (`MustParse`). Only call during startup, never in request paths | Google Go Decisions |

### Python

| Rule | Source |
|------|--------|
| Specific exception types, not bare `except:` | PEP 8, Google Python |
| `raise NewError() from original` to preserve chain | PEP 3134 |
| `try/except` around narrowest code | Google Python |
| Custom exceptions inherit `Exception`, not `BaseException` | PEP 8 |
| Context managers (`with`) for resource cleanup | Google Python |
| Never `assert` for runtime validation (stripped in optimized mode) | Google Python |
| **asyncio**: `asyncio.create_task()` for concurrent coroutines, `asyncio.gather()` for parallel. Always cancel tasks on shutdown. Use `async with` for async context managers | asyncio docs |

### Shell

| Rule | Source |
|------|--------|
| `set -euo pipefail` at top of every script | Google Shell |
| `trap cleanup EXIT` for cleanup | Convention |
| Explicit return code checking for critical commands | Google Shell |
| Functions return exit codes (0 success, non-zero failure) | Google Shell |

### Cross-Cutting: Retry Pattern

All external HTTP calls and DB connections should have retry logic with exponential backoff + jitter: `delay = min(baseDelay * 2^attempt + randomJitter, maxDelay)`. Max retries: 3-5. (Google SRE, AWS best practices)

---

## 8. Type Safety

### TypeScript (Google TS, Microsoft)

| Rule | Source |
|------|--------|
| `strict: true` in tsconfig | Google TS |
| **Never `any`** — use `unknown` + type guards | Google TS |
| `interface` for object shapes; `type` for unions/intersections/utilities | Google TS |
| `as const` for literal types; derive unions with `typeof obj[keyof typeof obj]` | Modern TS |
| `readonly` for immutable properties; `Readonly<T>` for function params that shouldn't be mutated | Google TS |
| `import type` for type-only imports | Google TS |
| No `namespace` — use ES modules | Google TS |
| `@ts-expect-error` over `@ts-ignore` | Google TS |
| Discriminated unions over type casting | Google TS |
| No non-null assertions (`!`) unless provably defined | Google TS |
| **No `const enum`** — breaks module boundaries, invisible to JS consumers. Use plain `enum` or `as const` | Google TS |
| **Switch exhaustiveness**: handle all union/enum cases. Use `const _exhaustive: never = value` in default for compile-time guarantee | typescript-eslint `switch-exhaustiveness-check` |
| **No enum boolean coercion** — never `if (enumValue)`. Always `if (status === Status.ACTIVE)` | Google TS |
| **Avoid complex mapped/conditional types** — prefer simple explicit types. Conditional type evaluation is underspecified across TS versions | Google TS |
| **Null vs undefined**: prefer optional fields (`field?: T`) over `field: T \| undefined`. Pick one convention per project | Google TS |
| **Immutability**: `Object.freeze()` for runtime + `as const` for compile-time on config objects | Convention |

### Go (Effective Go, Google Go)

| Rule |
|------|
| Define interfaces at consumer side, not implementer |
| Small interfaces (1-3 methods); compose larger ones |
| Accept interfaces, return concrete types |
| `any` (alias `interface{}`) only when truly necessary |
| Generics (Go 1.18+) over `interface{}` for typed collections |
| Struct embedding for composition |
| **Channel direction in signatures** — specify `chan<-` or `<-chan` in params/returns. Prevents misuse, communicates ownership |

### Python (PEP 484, Google Python)

| Rule |
|------|
| Type hints on all function signatures |
| `mypy` or `pyright` for static checking |
| `Protocol` (PEP 544) for structural subtyping |
| `TypedDict` for dict-with-known-keys |
| Avoid `Any` — use `object` when truly generic |
| **`@dataclass` for internal data**; **`Pydantic BaseModel` for trust boundaries** (API input, config, user input). Pydantic validates at runtime; dataclass does not |
| `pathlib.Path` over `os.path` for all path manipulation — more readable and type-safe |

### API Response Pattern

Define a generic response wrapper: all API functions return a discriminated union for consistent error handling.

```typescript
type ApiResponse<T> =
  | { data: T; error?: never }
  | { data?: never; error: ApiError };
```

---

## 9. Code Output & Logging

### Universal Rules

| Rule | Source |
|------|--------|
| **No `console.log` / `print` / `fmt.Println` in production** — use structured logger | All production guides |
| Structured logging: JSON format with `timestamp`, `level`, `traceId`, `service`, `message`, `context` | 12-Factor, Google SRE |
| Log levels: `DEBUG` (dev diagnostics), `INFO` (business events), `WARN` (recoverable), `ERROR` (needs attention), `FATAL` (exit) | Syslog/RFC 5424 |
| Log messages must include context: request ID, user ID, operation | Google SRE |
| **Never** log sensitive data: passwords, tokens, PII | OWASP |

### Language-Specific Loggers

| Language | Logger | Example |
|----------|--------|---------|
| TS/JS | `pino` / `winston` | `logger.info({ userId, action: 'user_created' }, 'User account created')` |
| Go | `log/slog` (1.21+) / `zerolog` / `zap` | `slog.Info("user created", "user_id", userID)` |
| Python | `logging` stdlib | `logger.info("User created", extra={"user_id": user_id})` |
| Shell | stderr + function | `log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $*" >&2; }` |

---

## 10. React

### Component Rules (CLAUDE.md: function components only, Props via interface)

| Rule | Source |
|------|--------|
| **Key prop: stable unique ID** — use database IDs/UUIDs. **Never** array index (when items reorder/insert/delete). **Never** `Math.random()` | React docs |
| **Key for state reset** — change `key` to force unmount/remount and reinitialize state. Prefer over manual reset logic | React docs |
| **Conditional rendering**: prefer early return for "not ready" states. `&&` guard only when left side is always boolean (avoid `0 && <Comp />` rendering `0`). Complex conditions → extract to variable | React docs |
| **Composition over prop drilling** — use children/render props for 2+ levels of threading. Context for cross-cutting concerns. Max 3 levels of intermediate props | React docs |

### useEffect Rules

| Rule | Source |
|------|--------|
| **Cleanup required**: every effect with subscriptions, timers, event listeners, or AbortControllers must return a cleanup function | React docs |
| **Avoid unnecessary effects** — do NOT use useEffect for: transforming data (compute during render), handling user events (use event handlers), resetting state on prop change (use `key`), deriving state | React "You Might Not Need an Effect" |
| Dependency array must be complete and correct | ESLint `react-hooks/exhaustive-deps` |

### State Management

| Rule | Source |
|------|--------|
| **State colocation**: keep state as close as possible to the component that uses it. Lift only when siblings need it. Global store only when many distant components share it | Kent C. Dodds, convention |
| Derive values during render instead of storing in state | React docs |

### Performance & Boundaries

| Rule | Source |
|------|--------|
| **Don't over-memoize**: `useMemo`/`useCallback` only when (a) passing to `React.memo` child, (b) used as `useEffect` dependency, (c) genuinely expensive computation. React 19+ Compiler auto-memoizes | React docs, Kent C. Dodds |
| **Error Boundaries**: wrap route-level and critical UI sections. Every lazy-loaded component must have Suspense + ErrorBoundary wrapper | React docs |
| **Code splitting**: route-level components use `React.lazy()` + `<Suspense fallback={...}>` | React docs |

---

## 11. Testing

### File Naming

| Language | Convention | Source |
|----------|-----------|--------|
| TS/JS | `*.test.ts` / `*.spec.ts` colocated or `__tests__/` | Jest/Vitest |
| Go | `*_test.go` in same package (white-box) or `_test` package (black-box) | Go convention |
| Python | `test_*.py` in `tests/` directory | pytest |
| Shell | `*_test.sh` or `bats` framework | bats |

### Structure: AAA (Arrange-Act-Assert)

All tests follow Arrange-Act-Assert pattern. Go uses table-driven tests as default.

### Rules

| Rule | Source |
|------|--------|
| Test names describe behavior: `should_return_404_when_user_not_found` | BDD convention |
| One assertion concept per test | Clean Code, Google Testing Blog |
| No logic in tests: no `if`, `for`, `switch` | Google Testing Blog |
| Tests must be independent: no shared mutable state, no order dependency | All frameworks |
| Use fakes over mocks when possible; mocks for interaction verification only | Google Testing Blog |
| Test public API, not implementation details | Google Testing Blog |
| Coverage: 80% line minimum; 100% for critical paths | Convention |
| Go: prefer table-driven tests | Google Go |
| Go: **`t.Helper()`** at start of every test helper — points errors to caller, not helper | Google Go |
| Go: **`t.Cleanup()`** for teardown (runs after test + subtests, works with parallel) | Google Go |
| Go: **`t.Run()`** subtests for selective running, isolation, and parallel execution | Google Go |
| Go: **`t.Parallel()`** for concurrent tests; capture loop var: `tc := tc` in table-driven | Uber Go |
| Go: failure messages: `t.Errorf("Func(%v) = %v, want %v", input, got, want)`. Use `cmp.Diff` for structs | Go Code Review Comments |
| Go: **never `t.Fatal()` from goroutines** — use `t.Error()` + return instead | Google Go |
| Go: `TestMain(m *testing.M)` for package-level setup; always call `os.Exit(m.Run())` | Go testing docs |
| Python: `pytest` over `unittest` | Convention |

### Mock Strategy

| Strategy | When to Use |
|----------|-------------|
| **Fakes** (in-memory impl) | Default choice for data stores, APIs |
| **Stubs** (canned responses) | External services with predictable responses |
| **Mocks** (verify interactions) | Need to verify specific call + args |
| **Never mock what you don't own** | Wrap third-party libs, mock the wrapper |

---

## 12. Security

### Input Validation (OWASP)

| Rule |
|------|
| Validate ALL external input at system boundaries |
| Allowlist over denylist |
| Schema validation: `zod`/`joi` (TS), `pydantic` (Python), Go struct tags |
| Validate types, ranges, lengths, formats |
| Sanitize HTML output (`DOMPurify`) to prevent XSS |
| **Parameterized queries for ALL DB operations** — never string concatenation |

### Secret Handling

| Rule | Source |
|------|--------|
| Never hardcode secrets in source | OWASP |
| Environment variables or secret managers (Vault, AWS SM) | 12-Factor |
| `.env`, `*.pem`, `*.key`, `credentials.json` in `.gitignore` | Convention |
| `crypto.timingSafeEqual()` for secret comparison | Node.js docs |
| Hash passwords with `bcrypt`/`scrypt`/`argon2`, never MD5/SHA | OWASP |
| Never log secrets, even at DEBUG level | OWASP |
| **Go**: `crypto/rand` for keys/tokens/secrets, **never** `math/rand` | Go Code Review Comments |

### Environment & Startup

| Rule | Source |
|------|--------|
| **Validate ALL required env vars at startup** — before any initialization. Use `zod`/`envalid` (TS), `pydantic` (Python). Fail fast with clear messages listing missing/invalid vars | 12-Factor, convention |
| **Idempotency for mutations**: all write API endpoints must be idempotent. `PUT`/`DELETE` naturally idempotent. `POST` with side effects needs idempotency key | REST convention, Stripe |
| **Transaction isolation**: choose level explicitly for critical transactions. Document when not using default (`READ COMMITTED`) | SQL standard |

### Shell Security (Google Shell)

- **Always** quote variable expansions to prevent injection
- Never `eval` with user input
- Use arrays for command construction

---

## 13. Performance Anti-Patterns

### TypeScript/JavaScript

| Anti-Pattern | Fix |
|-------------|-----|
| `for...in` on arrays | `for...of` / `.map()` / `.forEach()` |
| Functions inside loops | Define outside, reference inside |
| `delete obj.prop` (deoptimizes V8) | Set `undefined` or restructure |
| Sync file I/O in server | `fs.promises` / async APIs |
| `JSON.parse(JSON.stringify())` deep clone | `structuredClone()` |
| Regex in hot loops uncached | Compile once, reuse |
| Closures capturing large scopes | Minimize captured scope; `WeakMap` for caches |
| **Sequential `await` in loops** for independent ops | Collect promises, `Promise.all()` |

### Go

| Anti-Pattern | Fix |
|-------------|-----|
| String `+=` in loops | `strings.Builder` |
| Not pre-allocating slices | `make([]T, 0, expectedLen)` |
| Goroutine leaks (no cancel) | `context.Context` for cancellation |
| Defer in tight loops | Manual cleanup or restructure |
| `interface{}` where generics suffice | Generics (1.18+) |
| **Copying structs with pointer fields** (slices, maps, `sync.Mutex`, `bytes.Buffer`) | Be aware shared underlying data; deep copy if needed |
| **Goroutine without clear lifetime** | Document when/how it exits; use `sync.WaitGroup` or `chan struct{}` |

### Python

| Anti-Pattern | Fix |
|-------------|-----|
| `+` string concat in loops | `''.join(parts)` |
| `list.append()` where comprehension works | List comprehension |
| Not using generators for large data | Generator expressions / `yield` |
| `import *` | Explicit imports |
| `os.path` for path manipulation | `pathlib.Path` |
| Many instances without `__slots__` | `@dataclass(slots=True)` (3.10+) — 30-40% memory reduction |

### SQL

| Anti-Pattern | Fix |
|-------------|-----|
| `SELECT *` in production | Explicit column list |
| N+1 queries | JOIN or batch |
| Missing indexes on WHERE/JOIN columns | Add indexes |
| `LIKE '%pattern'` | Full-text search |
| No `EXPLAIN ANALYZE` | Profile all slow queries |
| **Nested subqueries** for complex logic | CTE (`WITH` clause) — more readable, referenceable |
| **Self-joins for rankings/running totals** | Window functions (`ROW_NUMBER`, `RANK`, `LAG`, `SUM() OVER()`) |
| **SELECT-then-INSERT for upserts** | `ON CONFLICT DO UPDATE` (PG) / `ON DUPLICATE KEY UPDATE` (MySQL) |
| **No explicit column list in INSERT** | Always specify: `INSERT INTO t (col1, col2) VALUES (...)` |

### Memory Management

| Language | Rule |
|----------|------|
| TS/JS | `WeakMap`/`WeakSet` for cache-like structures; watch event listener leaks |
| Go | `sync.Pool` for short-lived objects; profile with `pprof` before optimizing |
| Python | `__slots__` on data classes with many instances; generators over full lists |
| Shell | Process large files line-by-line, not load into variable |

---

## 14. Git & Commit

### Conventional Commits

**Format**: `<type>(<scope>): <subject>`

| Type | Description | Version Bump |
|------|-------------|-------------|
| `feat` | New feature | MINOR |
| `fix` | Bug fix | PATCH |
| `docs` | Documentation only | None |
| `style` | Formatting — no logic change | None |
| `refactor` | Neither fix nor feature | None |
| `perf` | Performance improvement | PATCH |
| `test` | Tests | None |
| `build` | Build system / deps | None |
| `ci` | CI config | None |
| `chore` | Maintenance | None |

Breaking changes: `feat(api)!: remove deprecated endpoint` or `BREAKING CHANGE:` footer.

### Commit Message Rules

| Rule | Source |
|------|--------|
| Subject: max 50 chars (hard: 72); imperative mood; lowercase after type; no period | Tim Pope, Conventional Commits |
| Body: wrap 72 chars; explain **why** not what | Convention |
| One logical change per commit | All conventions |
| Never commit generated files or secrets | Convention |

### Branch Naming

**Format**: `<type>/<ticket>-<short-description>` (kebab-case, under 50 chars)

```
feat/PROJ-123-user-auth
fix/PROJ-456-null-pointer
refactor/PROJ-789-extract-module
```

### PR Conventions (Google Engineering Practices)

| Rule |
|------|
| Under 400 lines of diff (excluding generated/config) |
| One logical change per PR |
| Title: conventional commit format |
| Description: summary + motivation + test plan |
| All CI checks pass; at least one code owner approval |
| Squash-merge feature branches |

---

## 15. Go Backend & Concurrency

### Concurrency Primitives

| Rule | Source |
|------|--------|
| **Goroutine lifetime must be clear** — document exit condition. Use `context.Context` for cancellation, `sync.WaitGroup` for tracking | Go Code Review Comments |
| **Never fire-and-forget goroutines** — all goroutines must be waited on or cancellable. No `go func()` without ownership of exit | Uber Go |
| **Channel size: 0 or 1** by default. Larger buffers need explicit justification | Uber Go, Google Go |
| **`sync.Mutex`**: zero value is valid. Never use pointer to mutex. Embed as unexported field. **Never expose** | Uber Go, Effective Go |
| **`sync.Once`** for thread-safe lazy init. Never double-check locking manually | Effective Go |
| **`sync.WaitGroup`**: call `wg.Add(n)` before spawning goroutines, not inside them | Effective Go |
| **`sync/atomic`** for simple shared counters/flags. Prefer over mutex for single-value ops | Uber Go |
| **No goroutines in `init()`** — creates unpredictable startup ordering | Uber Go |

### Struct & Interface Patterns

| Rule | Source |
|------|--------|
| **Pointer vs value receiver**: Pointer when: mutates receiver, has `sync.Mutex`/uncopyable field, large struct. Value when: map/func/chan, small immutable struct. **Never mix** on same type | Go Code Review Comments |
| **Zero value usability**: design structs so zero value works without init (like `sync.Mutex`, `bytes.Buffer`). Document when zero value is NOT valid | Effective Go |
| **Struct tags**: JSON `json:"field_name,omitempty"` (snake_case), DB `db:"column_name"`, validate `validate:"required,min=1"`. Use `musttag` linter | Convention |
| **Compile-time interface check**: `var _ http.Handler = (*MyHandler)(nil)` at package level | Uber Go |
| **Don't copy structs with pointer fields** (`bytes.Buffer`, `sync.Mutex`, anything with lock/slice) | Go Code Review Comments |
| **Type switch** over chain of `if v, ok := x.(T)` assertions | Effective Go |
| **Avoid embedding in public structs** — leaks implementation details. Prefer explicit delegation | Uber Go |
| **Named returns**: only when 2-3 params of same type need disambiguation or value modified in defer. No naked returns in medium+ functions | Go Code Review Comments |
| **Avoid naked parameters** — don't pass multiple bools/ints positionally. Use option structs or named types | Uber Go |

### HTTP Server

| Rule | Source |
|------|--------|
| **Graceful shutdown**: `signal.NotifyContext(ctx, SIGTERM, SIGINT)` + `server.Shutdown(ctx)`. Order: stop accepting → drain in-flight → close pools. Timeout: 15-30s | Production convention |
| **Always set server timeouts**: `ReadTimeout`, `WriteTimeout`, `IdleTimeout`. Never bare `http.ListenAndServe` (Slowloris vulnerability) | Go docs, OWASP |
| **Client timeouts**: set `http.Client.Timeout` and use context deadline | Go docs |
| **Context in handlers**: use `r.Context()`, pass to all downstream calls. Never `context.Background()` inside handlers | Go Code Review Comments |
| **Middleware pattern**: `func(next http.Handler) http.Handler`. Chain: logging → auth → recovery → handler | Convention |
| **Health endpoints**: `/healthz` (liveness) + `/readyz` (readiness, checks DB/deps). Return 200/503 | Kubernetes, 12-Factor |

### Database

| Rule | Source |
|------|--------|
| **`sql.DB` is a pool** — create once, share globally. Configure: `SetMaxOpenConns`, `SetMaxIdleConns` (25-50% of max), `SetConnMaxLifetime` (5min), `SetConnMaxIdleTime` (5min) | Go database docs |
| **Transaction pattern**: `defer tx.Rollback()` immediately after `BeginTx`. If `Commit()` succeeds, rollback is no-op. Handles panics and early returns | Go database docs |
| **Context in all DB calls**: `QueryContext`, `ExecContext`, `PrepareContext` — never non-context variants | Convention |
| **Monitor pool stats**: `db.Stats()` for `WaitCount`/`WaitDuration`. Export as metrics | Go database docs |

### Project Layout

| Rule | Source |
|------|--------|
| `cmd/` for binaries (thin `main.go` wires deps), `internal/` for private packages (compiler-enforced), `pkg/` only for external consumption | golang-standards |
| **Exit once in `main()`**: extract to `run() error`. Pattern: `func main() { if err := run(); err != nil { fmt.Fprintf(os.Stderr, ..); os.Exit(1) } }` | Uber Go |
| **No mutable package-level globals** — use dependency injection via constructors. Globals break testing and create coupling | Uber Go |
| **`internal/` packages** for domain logic that shouldn't leak to consumers | Go docs |
| **`go mod tidy`** before commit. `go mod verify` in CI | Go modules docs |

### Performance

| Rule | Source |
|------|--------|
| **`strconv` over `fmt`** for conversions — `strconv.Itoa(n)` is ~6x faster than `fmt.Sprintf("%d", n)` | Uber Go |
| **Preallocate maps**: `make(map[K]V, expectedLen)` when size known | Uber Go |
| **Escape analysis**: return pointers forces heap allocation. Profile with `go build -gcflags='-m'` | Google Go |

---

## 16. Node.js Backend

### Process & Lifecycle

| Rule | Source |
|------|--------|
| **Graceful shutdown**: handle `SIGTERM`/`SIGINT` → `server.close()` → drain requests → close DB pools → `process.exit(0)`. Set forced-exit timeout (10s). Use `server.closeIdleConnections()` (Node 18.2+) | goldbergyoni, Express docs |
| **Uncaught exception handler**: register `process.on('uncaughtException')` and `process.on('unhandledRejection')` — log + flush + **exit process** (let PM2 restart). Never continue after uncaughtException | goldbergyoni, Node.js docs |
| **Health check**: `GET /health` checking DB, memory, event loop. Return 200/503 | Express docs, k8s convention |
| **Startup order**: validate config → connect DB/Redis → start HTTP server → register signal handlers. Fail fast on any step | 12-Factor, goldbergyoni |

### Error Handling

| Rule | Source |
|------|--------|
| **Operational vs programmer errors**: operational (invalid input, timeout — handle gracefully) vs programmer (TypeError, null ref — crash and restart). Never try/catch programmer errors into recovery | goldbergyoni, Joyent |
| **Koa error middleware**: first middleware: `app.use(async (ctx, next) => { try { await next() } catch (err) { ... } })`. Also `app.on('error', handler)` | Koa docs |
| **Express error middleware**: 4 params `(err, req, res, next)`, registered **last**. Async routes need `catchAsync()` or `express-async-errors` | Express docs |
| **Koa vs Express async**: Koa auto-propagates async errors through `await next()`. Express silently drops them — **always** use `catchAsync()` wrapper | Koa/Express docs |
| **Error response format**: `{ error: { code: 'VALIDATION_ERROR', message: '...', details?: [...] } }`. Never leak stack traces in production | OWASP, goldbergyoni |

### Middleware Ordering

Enforce this order:
1. Request ID generation
2. Security headers (`helmet`)
3. CORS
4. Rate limiting
5. Body parsing (with size limits: `json({ limit: '100kb' })`)
6. Request logging (`pino-http`)
7. Auth/session
8. Validation
9. Business logic routes
10. 404 handler
11. Error handler (**last**)

### Security

| Rule | Source |
|------|--------|
| **`helmet()`** as first middleware — sets 14+ security headers (HSTS, CSP, X-Frame-Options etc.) | OWASP, Express security |
| **CORS**: never `origin: '*'` in production. Explicitly allowlist origins | OWASP |
| **Rate limiting**: `express-rate-limit` globally, stricter on auth endpoints (10 req/15min for `/login`). Redis store for multi-instance. Include `Retry-After` header | OWASP, goldbergyoni |
| **JWT**: access tokens 15min (in memory), refresh tokens in `httpOnly`+`secure`+`sameSite:'strict'` cookies. Rotate refresh on each use. Prefer RS256/ES256 over HS256 for distributed systems | OWASP, JWT best practices |
| **`npm audit`** in CI pipeline. `--production` to skip devDeps. `.npmrc`: `engine-strict=true`, `save-exact=true` | OWASP NPM Cheat Sheet |
| **Request payload limits**: set `bodyParser` size explicitly. Configure file upload limits (size + count) | OWASP, goldbergyoni |
| **ORM raw SQL**: `sql.raw()` / `$queryRaw` bypass parameterization. Lint all raw SQL. Always use `$1`/`?` placeholders | OWASP |

### API Patterns

| Rule | Source |
|------|--------|
| **Request ID**: generate UUID at entry middleware. Store in `AsyncLocalStorage`. Attach to all logs, error responses, outbound requests | goldbergyoni |
| **Validation middleware**: Zod/Joi at middleware layer **before** business logic. Return 400 with structured errors. Attach typed data to `ctx.state` (Koa) / `req.validated` (Express) | goldbergyoni |
| **Request timeout**: `server.setTimeout(30000)` + per-route for long ops. Downstream calls: `signal: AbortSignal.timeout(ms)` | Node.js docs |
| **SSE**: headers `text/event-stream` + `Cache-Control: no-cache` + `X-Accel-Buffering: no` (nginx). Use `res.write()`. Cleanup on `req.on('close')`. Heartbeat every 15-30s. `res.flush()` if compression active | MDN, convention |
| **Pagination**: cursor-based for feeds (no skip cost), offset for admin UIs. Always cap `limit` server-side (max 100) | REST convention |

### Database

| Rule | Source |
|------|--------|
| **Connection pooling**: always pools (`pg.Pool`, `mysql2.createPool`), never single connections. Set `min`, `max`, `idleTimeoutMillis`, `connectionTimeoutMillis`. **Always release clients** (try/finally or pool.query shorthand) | node-postgres docs |
| **Transaction pattern**: `const client = await pool.connect(); try { await client.query('BEGIN'); ... COMMIT } catch { ROLLBACK; throw } finally { client.release() }`. With Drizzle: `db.transaction(async (tx) => { ... })` | pg/Drizzle docs |
| **Connection retry on startup**: exponential backoff (3-5 attempts). If all fail, log and exit — don't start serving without DB | goldbergyoni, 12-Factor |

### Performance

| Rule | Source |
|------|--------|
| **Don't block the event loop**: no sync APIs in server code (`fs.readFileSync`, `crypto.pbkdf2Sync`, `JSON.parse` on large payloads). Audit with `blocked-at` | Node.js official guide |
| **Worker threads for CPU tasks**: `piscina`/`workerpool` for image processing, PDF gen, heavy parsing. Pool size ≈ CPU cores. Never one worker per request | Node.js docs, goldbergyoni |
| **Streams for large data**: `pipeline()` from `stream/promises` for file I/O, HTTP proxying, CSV/JSON. Never load large files into memory | Node.js docs |
| **HTTP client keepAlive**: set `keepAlive: true` on `http.Agent` (Node <19) or use `fetch` (defaults keepAlive in 19+). Avoids TCP+TLS handshake per request | Node.js docs |
| **Memory monitoring**: `process.memoryUsage()` in health endpoint. `--max-old-space-size` for heap limit. PM2 `max_memory_restart` | goldbergyoni |

### Logging

| Rule | Source |
|------|--------|
| **Pino over Winston** for high-throughput: 6x faster (222k vs 36k ops/sec), async I/O, zero-allocation. Use `pino-http` (Express) / `koa-pino-logger` (Koa) | Pino benchmarks |
| **Request logging**: method, URL, status, response time, request ID. Place after request ID middleware. Exclude health check endpoints | Convention |
| **Child loggers**: `logger.child({ requestId, userId })` — all logs auto-include context. Pass via `AsyncLocalStorage` or `ctx.state.logger` | Pino docs |
| **Log to stdout in production** — let orchestrator handle collection. Never write to files in containers | 12-Factor, Docker convention |

### Testing

| Rule | Source |
|------|--------|
| **Supertest** for HTTP endpoint testing against actual app instance (full middleware chain) | goldbergyoni testing |
| **MSW/Nock** for external API mocking. MSW preferred (network-level, works in Node+browser). Reset between tests | MSW docs |
| **Test database**: separate from dev DB. Options: (a) transaction + rollback per test (fastest), (b) truncate between tests, (c) testcontainers. Use factory functions, not shared fixtures | goldbergyoni testing |
| **Integration tests**: test as consumer — real HTTP requests, assert status + response body. Happy paths + 400/401/403/404/500 | goldbergyoni testing |

### Module System

| Rule | Source |
|------|--------|
| **ESM for new projects**: `"type": "module"` in package.json. Use `.js` extension in imports | Node.js ESM docs |
| **`exports` field** in package.json for public API surface + conditional exports (import/require) | Node.js docs |

### Deployment (Docker)

| Rule | Source |
|------|--------|
| **Multi-stage build**: Stage 1 (build): all deps + compile TS. Stage 2 (prod): compiled output + prod `node_modules` + `node:20-slim`/`alpine`. 60-80% size reduction | OWASP Docker |
| **Non-root user**: `COPY --chown=node:node` then `USER node` before `CMD`. Set `NODE_ENV=production`. Never run as root | OWASP Docker |
| **`.dockerignore`**: exclude `node_modules`, `.git`, `.env*`, `tests/`, `coverage/` | Snyk, convention |
| **`dumb-init` or `--init`**: Node.js doesn't handle PID 1 signals correctly. Use init process to forward SIGTERM | OWASP Docker |
| **Config**: hierarchical, centralized. Separate by concern (server/db/auth/features). Never scatter `process.env.X` across business logic | goldbergyoni |

---

## Linter Quick Reference

### TypeScript ESLint

```jsonc
{
  // Type safety
  "@typescript-eslint/no-explicit-any": "error",
  "@typescript-eslint/no-unused-vars": "error",
  "@typescript-eslint/consistent-type-imports": "error",
  "@typescript-eslint/switch-exhaustiveness-check": "error",
  "@typescript-eslint/no-floating-promises": "error",
  "@typescript-eslint/no-misused-promises": "error",
  "@typescript-eslint/only-throw-error": "error",
  "@typescript-eslint/no-shadow": "error",
  "@typescript-eslint/no-use-before-define": "error",
  "@typescript-eslint/return-await": ["error", "in-try-catch"],
  "@typescript-eslint/no-unnecessary-condition": "warn",
  "@typescript-eslint/no-misused-spread": "error",
  // Expressions
  "@typescript-eslint/prefer-optional-chain": "error",
  "@typescript-eslint/prefer-nullish-coalescing": "error",
  "prefer-template": "error",
  "no-nested-ternary": "error",
  // Variables & style
  "prefer-const": "error",
  "no-var": "error",
  "eqeqeq": "error",
  "no-param-reassign": "error",
  "no-await-in-loop": "warn",
  "no-magic-numbers": ["warn", { "ignore": [0, 1, -1], "ignoreArrayIndexes": true }],
  // Complexity
  "max-lines": ["warn", { "max": 400 }],
  "max-lines-per-function": ["warn", { "max": 50 }],
  "max-params": ["warn", { "max": 4 }],
  "complexity": ["warn", { "max": 10 }],
  "max-depth": ["warn", { "max": 4 }]
}
```

### Go: golangci-lint

```yaml
linters:
  enable:
    # Default
    - errcheck          # check error returns
    - govet             # examines source code
    - staticcheck       # advanced static analysis
    - unused            # unused code
    - gosimple          # simplifications
    - ineffassign       # ineffectual assignments
    - gocyclo           # cyclomatic complexity
    - gofmt             # formatting
    - goimports         # import ordering
    - revive            # flexible linter
    # Error handling
    - errorlint         # non-wrapping error comparisons, missing %w
    - wrapcheck         # errors from external packages must be wrapped
    - nilerr            # returning nil when error was checked
    - nilnil            # prevents (nil, nil) returns
    # Safety
    - noctx             # HTTP requests without context.Context
    - bodyclose         # unclosed http.Response.Body
    - gosec             # security: SQL injection, hardcoded creds, weak crypto
    - exhaustive        # switch on enum handles all cases
    # Quality
    - goconst           # repeated literals → constants
    - nestif            # deeply nested ifs
    - funlen            # max function length
    - gocritic          # meta-linter (100+ checks)
    - prealloc          # slice pre-allocation
    - musttag           # marshal struct tags
    - sloglint          # consistent slog usage
```

### Python: ruff

```ini
[tool.ruff]
select = ["E", "W", "F", "I", "N", "UP", "B", "S", "C4", "SIM"]
line-length = 88
```

### Shell: ShellCheck

```bash
shellcheck -s bash -e SC1090 script.sh
# Key: SC2086 (quote vars), SC2046 (quote to prevent splitting), SC2155 (declare/assign separately)
```

---

## How to Apply

### When Writing Code
1. Check naming conventions (Section 1) for current language
2. Use correct operators (Section 3) — `===`, `??`, `?.`, template literals
3. Apply function design limits (Section 4) — 50 lines, 4 params, complexity 10
4. Follow file structure order (Section 5)
5. Add documentation for public APIs (Section 6)
6. Use proper error handling patterns (Section 7)
7. Follow React rules if applicable (Section 10)
8. **Go backend**: check concurrency safety, struct patterns, server timeouts (Section 15)
9. **Node.js backend**: check middleware ordering, process lifecycle, security headers (Section 16)
10. Run linter before commit (Linter Reference)

### During Code Review
1. Scan for naming violations and magic numbers/strings
2. Check function length and complexity
3. Verify error handling is complete (no swallowed errors, no floating promises, proper wrapping)
4. Check type safety (no `any`, proper guards, exhaustive switches)
5. Verify no `console.log` / `print` in production code
6. Check React patterns (key props, effect cleanup, memoization necessity)
7. **Go**: goroutine lifetime clear? Receiver consistency? Errors wrapped not just logged? Server timeouts set?
8. **Node.js**: graceful shutdown? Security middleware? Connection pooling? Event loop not blocked?
9. Check test coverage and quality

### Key Reminders
- **CLAUDE.md invariants always apply** on top of these rules
- **System design rules** are in `/design-guide`, not here
- **Detailed examples** are in `~/Knowledge/04-Engineering/Industry-Standard-Code-Conventions.md`
- **When in doubt, choose clarity over cleverness**
