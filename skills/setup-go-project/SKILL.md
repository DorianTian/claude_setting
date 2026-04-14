---
name: setup-go-project
description: "Scaffold a new Go project following Futu FRPC convention — standardized directory structure, layered architecture (business/repository/external/cache), Go PB artifact library v1 integration, GORM Gen setup. Use this skill whenever the user wants to create a new Go service, scaffold a Go project, init a Go FRPC project, set up Go project structure, or asks about Futu Go project conventions. Also trigger when the user mentions: Go 新项目, Go 目录结构, FRPC 脚手架, 新建 Go 服务, Go 项目规范."
user-invocable: true
---

# Futu Go Project Scaffolding

Based on the FRPC scaffold, this skill defines the standard Go project structure, layered architecture, and tooling conventions used at Futu. The goal: every Go project follows the same directory layout so engineers can switch between projects without re-learning structure.

## Arguments

$ARGUMENTS

If no arguments provided, ask for:
1. **Project name** (e.g., `my-service`)
2. **Whether to use Go PB artifact library v1** (recommended for new projects, requires FRPC v1.16.0+)
3. **Entry points needed**: service (SRPC) / web (HTTP) / worker (cron/kafka/rmq) — can be multiple

---

## Recommended Directory Structure

Based on FRPC scaffold output, with additional directories for business logic separation. Directories marked 🟡 are optional — skip if not needed.

```
cmd/                              # Entry point (FRPC generated)
├── conf/                         # Config files (FRPC generated)
├── gorm/                         # 🟡 GORM Gen code generation entry
│   └── main.go
├── internal/
│   ├── app/
│   │   ├── business/             # Business logic (NO SQL here)
│   │   │   └── {module}/        # One dir per business module
│   │   │       ├── business.go   # Core logic
│   │   │       └── validate.go   # Parameter validation
│   │   │
│   │   ├── common/               # Shared utilities (NOT coupled to business)
│   │   │   ├── constants/        # Enums, status codes, global constants
│   │   │   │   └── lang.go
│   │   │   ├── config/           # Config parsing (reads conf.toml)
│   │   │   │   └── center_config.go
│   │   │   ├── errors/           # Error definitions
│   │   │   │   ├── error_code.go       # Error code constants
│   │   │   │   └── error_handler.go    # Error handling utils
│   │   │   └── utils/            # Generic helpers (map, slice, time)
│   │   │       ├── map.go
│   │   │       └── slice.go
│   │   │
│   │   ├── middleware/           # Request pre/post processing
│   │   │   ├── request_handler.go  # Request data processing
│   │   │   └── auth.go             # Auth & access control
│   │   │
│   │   ├── model/                # Data models (FRPC generated base)
│   │   │   └── db/               # GORM Gen generated models
│   │   │       └── {table}_model.go
│   │   │
│   │   ├── cache/                # 🟡 Cache layer (Redis + local)
│   │   │   ├── redis_key.go      # Redis key definitions
│   │   │   ├── redis.go          # Redis operations
│   │   │   └── local_cache.go    # In-memory cache
│   │   │
│   │   ├── repository/           # Data access layer (DB CRUD)
│   │   │   └── {entity}_repo.go
│   │   │
│   │   ├── external/             # 🟡 External service calls
│   │   │   └── {service_name}/   # One dir per external service
│   │   │       └── {service}.go
│   │   │
│   │   └── service/              # FRPC generated — delegates to business
│   │       └── service_tmpl.go
│   │
│   ├── web/                      # 🟡 HTTP entry (gin-based)
│   │   ├── router.go             # Route definitions
│   │   └── handler.go            # HTTP handlers → business
│   │
│   └── worker/                   # 🟡 Background tasks (FRPC generated)
│       ├── cron/
│       ├── timer/
│       ├── kafka/
│       └── rmq/
│
└── proto/                        # Protocol definitions
    ├── self/                     # This service's own protos
    └── {dependency}/             # Dependent service protos
```

---

## Layer Architecture

The call chain is strict — violations break separation of concerns.

```
┌─────────────────┐  ┌────────────────────┐  ┌──────────────┐
│ service (SRPC)  │  │ worker (cron/mq)   │  │  web (HTTP)  │
└────────┬────────┘  └─────────┬──────────┘  └──────┬───────┘
         │                     │                     │
         └─────────────┬───────┘─────────────────────┘
                       ▼
              ┌─────────────────┐
              │    business     │  ← Core logic lives here
              └───────┬─────────┘
                      │
              ┌───────▼─────────┐
              │     cache       │  ← Redis / local memory
              └───────┬─────────┘
                      │
         ┌────────────┴────────────┐
         ▼                         ▼
┌─────────────────┐     ┌──────────────────┐
│    external     │     │   repository     │
│  (RPC/HTTP)     │     │   (DB CRUD)      │
└────────┬────────┘     └────────┬─────────┘
         │                       │
    ┌────┴────┐            ┌─────┴──────┐
    │SRPC/HTTP│            │MySQL/BH/ES │
    └─────────┘            └────────────┘
```

### Layer Rules

| Layer | Responsibility | Can Call | Cannot Call |
|-------|---------------|----------|-------------|
| **service** | FRPC entry, delegates to business | business | repository, external, cache directly |
| **web** | HTTP entry (gin), route + delegate | business | repository, external, cache directly |
| **worker** | Background tasks entry | business | repository, external, cache directly |
| **business** | Core logic, orchestration | repository, external, cache | — |
| **cache** | Redis/local memory R/W | — | business |
| **repository** | DB CRUD operations | model | business, external |
| **external** | Remote service calls | — | business, repository |
| **model** | Data structures only | — | everything |
| **middleware** | Request pre/post processing | — | business (intercept only) |
| **common** | Utilities, constants, config | — | business, repository |

Key point: **business layer can directly access both external and repository** — cache sits alongside, not in between. The architecture diagram shows cache as accessible from business, not as a mandatory passthrough.

### Layer Definitions

- **business**: Core program logic. Shields callers from data access details. Communicates with repository (DB), external (remote services), and cache. **No SQL statements in this layer** — all DB operations go through repository.
- **repository**: Direct communication with data sources. Executes raw CRUD. Maps to model structs. This is the only layer that touches the database.
- **external**: Manages outbound calls to other services (SRPC, HTTP). One subdirectory per external service for clean isolation.
- **cache**: Redis operations and local in-memory caching. Stores computed business data, DB query caches, etc.
- **model/db**: GORM Gen generated structs. Pure data structures, no logic.
- **middleware**: Request/response interception — auth, rate limiting, request transformation. Runs before business logic.
- **common**: Shared utilities that are NOT business-specific. Config parsing, constants, error codes, helper functions.
- **service**: FRPC framework generated. Receives RPC calls and forwards to business. Minimal logic here — just delegation.
- **web**: HTTP entry point (gin-based). Defines routes and handlers that forward to business. Similar role to service but for HTTP.
- **worker**: Background task entry points. Cron jobs, timer tasks, Kafka/RMQ consumers. Business logic forwarded to business layer.

---

## Scaffolding Workflow

### Step 1: Create FRPC Project

```bash
# Requires frpc_toolkit v1.11.0+
frpc_toolkit create -m "gitlab.futunn.com/xxx/example/frpc_demo" frpc_demo
```

### Step 2: Add Business Directories

After FRPC scaffold generates the base, create the additional directories:

```bash
cd frpc_demo

# Business logic layer
mkdir -p internal/app/business

# Common utilities
mkdir -p internal/app/common/{constants,config,errors,utils}

# Middleware
mkdir -p internal/app/middleware

# Cache layer (if needed)
mkdir -p internal/app/cache

# Repository layer
mkdir -p internal/app/repository

# External services (if needed)
mkdir -p internal/app/external

# GORM Gen (if using DB)
mkdir -p gorm
```

### Step 3: Set Up GORM Gen (if using DB)

Read `references/gorm-gen-guide.md` for the full GORM Gen configuration template and integration with FRPC.

Key points:
- Install: `go get -u gorm.io/gen`
- Generated models go to `internal/app/model/db/`
- Store (DAO) goes to `internal/app/store/`
- Run via `go run gorm/main.go`

### Step 4: Set Up Go PB Artifact Library v1 (recommended)

Read `references/pb-artifact-library.md` for complete setup instructions.

Key points:
- Requires FRPC v1.16.0+
- Simplifies directory structure by removing generated proto code from the project
- Import paths follow: `gitlab.futunn.com/artifact-go/{lib}/api/{pkg}` and `.../pb/{pkg}`
- Package name conversion: strip underscores, hyphens, dots → lowercase

### Step 5: Wire Up Layers

Create initial files following the layer responsibilities:

**business/{module}/business.go** — Core logic, calls repository/external:
```go
package category

import (
    "context"
    // import repository, external as needed
)

// CategoryBusiness handles category-related business logic
type CategoryBusiness struct {
    // inject dependencies
}

func NewCategoryBusiness() *CategoryBusiness {
    return &CategoryBusiness{}
}
```

**repository/{entity}_repo.go** — DB operations only:
```go
package repository

import (
    "context"
    // import model, store (GORM Gen DAO)
)
```

**service/service_tmpl.go** — FRPC generated, delegates to business:
```go
// Forward all logic to business layer
// Keep this file thin — just parameter passing
```

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Package | lowercase, no underscores | `category`, `cardrepo` |
| File | snake_case.go | `business.go`, `error_code.go` |
| Directory | snake_case or single word | `business/`, `common/` |
| Business module dir | domain noun | `category/`, `card/`, `order/` |
| External service dir | service name | `abt_service/`, `risk_service/` |
| Repository file | `{entity}_repo.go` | `card_repo.go` |
| Model file | `{table}_model.go` | `card_model.go` |
| Redis key file | `redis_key.go` | — |
| Error code file | `error_code.go` | — |

---

## Checklist for New Go Project

Use this as a verification list after scaffolding:

- [ ] FRPC project created via `frpc_toolkit create`
- [ ] `internal/app/business/` exists with at least one module
- [ ] `internal/app/common/` has constants, config, errors, utils as needed
- [ ] `internal/app/middleware/` has auth if service requires it
- [ ] `internal/app/model/db/` ready for GORM Gen output
- [ ] `internal/app/repository/` has repo files for each entity
- [ ] `internal/app/cache/` created if Redis/local cache needed
- [ ] `internal/app/external/` created if calling other services
- [ ] Layer call chain respected (no service→repository shortcuts)
- [ ] GORM Gen configured if using DB (see `references/gorm-gen-guide.md`)
- [ ] PB artifact library integrated if applicable (see `references/pb-artifact-library.md`)
- [ ] Proto files organized: `proto/self/` for own, `proto/` for dependencies
- [ ] Error codes follow Futu error code specification

---

## Reference Files

These contain detailed setup guides. Read them when the specific topic comes up:

- **`references/pb-artifact-library.md`** — Complete Go PB artifact library v1 guide: version requirements, frpc_toolkit commands, import paths, service registration, client usage, best practices, and FAQ/troubleshooting
- **`references/gorm-gen-guide.md`** — GORM Gen configuration template, FRPC integration, model generation patterns, and DAO code generation
