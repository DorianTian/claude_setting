---
name: design-guide
description: "System design rules & pattern reference manual. This is a REFERENCE TOOLKIT, not a decision-maker — use expert-team for decisions. Auto-load this skill as context when expert-team needs system design rules or pattern options. Also load directly via /design-guide when user explicitly asks for pattern lookup or design rule check. Covers: system design invariants (architecture, API, DB, observability, performance, security, testing, Git) + GoF patterns + data architecture patterns + frontend patterns + anti-patterns."
user-invocable: true
---

# System Design & Pattern Selection Guide

System design invariants + contextual design pattern selection.

## Arguments

$ARGUMENTS

If no arguments provided, ask:
1. What module/feature is being designed?
2. What problem needs solving? (extensibility, decoupling, state management, data flow, etc.)
3. What's the expected scale and complexity?

---

## Core Principle

> **Pattern is a means, not an end.** Only apply a pattern when the problem it solves actually exists in your codebase. The simplest correct solution is the best solution.

## Decision Flow

Before suggesting any pattern, evaluate in order:

1. **Can a plain function/module solve this?** → If yes, stop here
2. **Is the complexity justified by current requirements (not hypothetical future)?** → If no, use simpler approach
3. **Will the team understand and maintain this pattern?** → If uncertain, prefer explicit over clever
4. **Does Dorian's CLAUDE.md already mandate an approach?** → Invariants (layered architecture, SOLID, no-any) always apply on top of pattern choices

---

## System Design Invariants

基线：**Google SRE、AWS Well-Architected Framework、12-Factor App、Clean Architecture**。标记【强制】的规则不可违反，其余为推荐默认值，简单项目/原型期可酌情简化。

### 一、架构设计

- **分层架构【强制】**：至少 Controller/Handler → Service/UseCase → Repository/DAL 三层。禁止 Controller 直接操作数据库，禁止 Service 层感知 HTTP/RPC 协议细节
- **Bounded Context**：按领域边界划分模块，每个模块拥有独立的数据模型。跨模块通信通过明确的接口/事件，禁止共享数据库表
- **依赖方向单向**：外层依赖内层，内层不感知外层。基础设施（DB、MQ、外部 API）作为可替换的适配器注入
- **配置外置（12-Factor）**：环境相关配置通过环境变量或配置中心注入，禁止硬编码
- **无状态服务**：业务服务不在本地存储会话状态，状态下沉到 Redis/DB
- **故障隔离**：外部依赖调用配置超时和重试（指数退避）；关键链路增加熔断

### 二、API 设计

- **RESTful 语义**：资源用名词复数（`/users`），操作用 HTTP Method。禁止 `GET /getUser` 风格
- **版本管理**：API 带版本号（`/v1/`），破坏性变更必须升版本
- **统一响应格式**：`{ "code": 0, "message": "ok", "data": {}, "traceId": "xxx" }`，错误附 error code + message
- **分页标准化**：`cursor` 游标分页（大数据量）或 `page/pageSize`（后台管理），返回 `total` 和 `hasMore`
- **幂等设计**：写操作必须支持幂等，关键操作使用 idempotency key
- **入参校验**：API 边界严格校验，内部方法信任上游数据。校验失败返回 400 + 字段错误

### 三、数据库设计

- **范式与反范式平衡**：OLTP 至少 3NF；读多写少允许冗余，必须注释冗余原因和同步策略
- **主键策略**：自增 bigint 或 Snowflake ID，禁止 UUID 作为 InnoDB 聚簇索引主键
- **索引纪律**：慢查询必须有索引优化；联合索引最左前缀，区分度高的列在前；禁止低基数列独立索引
- **变更纪律**：Schema 变更通过 Migration 文件管理（版本化、可回滚），禁止手动执行 DDL
- **软删除**：业务数据 `deleted_at` 软删除，审计数据永不物理删除
- **大表策略**：预估超 1000 万行的表，设计之初规划分区或分表

### 四、错误处理与可观测性

- **结构化日志【强制】**：JSON 格式，含 `timestamp`、`level`、`traceId`、`service`、`message`、`context`
- **错误分级**：WARN（可自愈）、ERROR（需人工介入）、FATAL（立即告警）
- **链路追踪**：跨服务传播 traceId，请求可追溯完整调用链
- **健康检查**：`/health`（存活）+ `/ready`（就绪）
- **指标埋点（RED）**：Rate、Errors、Duration（P50/P95/P99）

### 五、性能工程

- **缓存策略**：Cache-Aside + TTL，防击穿/穿透/雪崩
- **异步化**：耗时操作走消息队列，接口返回任务 ID
- **批量优先**：禁止循环内 DB/API 调用，改为批量查询 + 内存关联
- **资源预算**：首屏 JS ≤ 200KB（gzipped）、LCP ≤ 2.5s、接口 P95 ≤ 500ms

### 六、安全基线

- **输入永不信任**：SQL 参数化查询，HTML 框架转义，禁止字符串拼接
- **认证鉴权分离**：独立中间件，不混在业务逻辑中
- **最小权限原则**：数据库账号按服务隔离，禁止 root 连生产
- **敏感数据脱敏**：日志/响应禁止输出密码、token、手机号等
- **密钥管理**：环境变量或 Vault 注入，禁止提交代码仓库

### 七、测试策略

- **测试金字塔**：单元（70%）→ 集成（20%）→ E2E（10%）
- **测试独立性**：可独立运行，不依赖执行顺序
- **边界覆盖**：空值、空数组、超长字符串、并发、超时

### 八、Git 与发布

- **Conventional Commits**：`feat:` / `fix:` / `refactor:` / `chore:` / `docs:` / `perf:` / `test:`
- **分支策略**：`main` + `develop` + `feature/*` + `hotfix/*`，Feature 分支 ≤ 3 天
- **Code Review 必须**：PR 合入至少 1 人 approve，描述含改了什么、为什么、如何验证
- **发布纪律**：禁止周五下午发布，上线必须有回滚方案

---

## Pattern Reference

### Creational Patterns — "How to create objects"

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Factory Method** | Creation logic varies by type; caller shouldn't know concrete class | Only 1-2 types, simple `new` suffices |
| **Abstract Factory** | Families of related objects that must be used together (e.g., UI theme system, cross-platform adapters) | Single product family, no variation needed |
| **Builder** | Complex object with many optional parameters; step-by-step construction | Object is simple (< 4 params), constructor suffices |
| **Singleton** | Truly global shared resource (DB connection pool, config registry) | **Almost always wrong in frontend.** Prefer DI/Context to provide instances |

### Structural Patterns — "How to compose objects"

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Adapter** | Integrating third-party API with incompatible interface | You control both sides — just change the interface |
| **Decorator** | Adding cross-cutting behavior without modifying target (logging, caching, retry, auth) | Deep decorator chains (> 3 levels) — use middleware pipeline instead |
| **Facade** | Simplifying complex subsystem with a unified API (e.g., SDK wrapper, service aggregation) | Subsystem is already simple |
| **Proxy** | Lazy loading, access control, caching transparent to caller | Adds indirection without clear benefit |
| **Composite** | Tree structures (file system, org chart, menu, AST) | Flat list — use array |

### Behavioral Patterns — "How objects interact"

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Strategy** | Algorithm/behavior varies at runtime; replaces if-else/switch chains with 3+ branches | 1-2 branches — if-else is clearer and more readable |
| **Observer / EventEmitter** | Decoupled 1:N notifications (state change → multiple UI updates) | Debugging event chains becomes impossible; prefer explicit calls for < 3 listeners |
| **Command** | Undo/redo, operation queue, macro recording, audit trail | Simple CRUD with no undo/history requirement |
| **State** | Object behavior changes with internal state; complex state transitions (order lifecycle, workflow engine) | ≤ 3 states with no complex transitions — switch/if is fine |
| **Chain of Responsibility** | Pipeline processing (middleware, validators, interceptors, approval chains) | Fixed processing order with no need for dynamic chain |
| **Template Method** | Shared algorithm skeleton with customizable steps (e.g., data export with different formats) | Composition via functions or hooks achieves the same goal |
| **Mediator** | Complex many-to-many interactions between objects (chat room, form field dependencies) | Simple direct communication between 2-3 objects |

### Data Architecture Patterns — "How to structure data flow"

| Pattern | Use When | Avoid When | Dorian's Domain Relevance |
|---------|----------|------------|--------------------------|
| **Repository** | Abstracting data access; multiple data sources; testability via mock/swap | Direct ORM/query builder in service layer suffices for simple CRUD | Data platform — separating Hive/Spark/MySQL access behind unified interface |
| **CQRS** | Read/write models diverge significantly; read-heavy with complex aggregated queries; separate scaling needs | Simple CRUD app — adds unnecessary split | Metadata management — read-heavy catalog queries vs. write-time governance rules |
| **Event Sourcing** | Full audit trail required; temporal queries ("what was the state at time T"); complex domain with undo | Simple state mutations; team lacks event-driven experience | Data lineage — tracking every schema change and its propagation |
| **Saga (Orchestration)** | Distributed transactions across services; compensation/rollback logic needed | Single-service transaction — use DB transaction | ETL pipeline — coordinating multi-step Flink jobs with failure recovery |
| **Saga (Choreography)** | Loosely coupled services reacting to events; no central coordinator needed | Need strict ordering or complex compensation | Event-driven metadata sync across systems |
| **Unit of Work** | Batch DB operations with atomic commit; change tracking | Simple single-entity saves | Batch metadata migration (7000+ tables) |

### Frontend-Specific Patterns

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Container/Presenter** | Separating data-fetching from rendering; reusable UI components | Small component with trivial data needs |
| **Compound Component** | Related components sharing implicit state (Tabs, Accordion, Select, Sidebar) | Independent components with no shared state |
| **Render Props / Custom Hooks** | Sharing stateful logic across multiple components | Logic is used in only one place — inline it |
| **Finite State Machine (XState)** | Complex UI states with defined transitions (multi-step form, async workflows, media player) | Binary toggle or simple loading/error/success state |
| **Module Federation** | Micro-frontend with independent deployment and shared dependencies | Monolithic app or small team — overhead not justified |
| **Optimistic Update** | Low-latency UX for frequent writes (likes, toggles, inline edits) | Critical data where server confirmation is required before showing result |

---

## Anti-Pattern Checklist

When reviewing code or architecture, watch for:

| Anti-Pattern | Symptom | Remedy |
|-------------|---------|--------|
| **God Object/Function** | One module does everything, 500+ lines | Split by SRP, extract domain services |
| **Premature Abstraction** | Abstraction created before second use case | Inline first, extract when pattern emerges (Rule of Three) |
| **Pattern Mania** | GoF patterns applied to 20-line modules | If-else is not a crime. Simple code > clever code |
| **Leaky Abstraction** | Implementation details leaking through interface | Tighten the contract, hide internals |
| **Shotgun Surgery** | One logical change touches 10+ files | Consolidate related logic into cohesive module |
| **Feature Envy** | Function uses more data from another module than its own | Move the function to where the data lives |
| **N+1 Query** | Loop DB/API calls inside iteration | Batch query + in-memory join |
| **Distributed Monolith** | Microservices that must deploy together | If services can't deploy independently, merge them back |
| **Cargo Cult Architecture** | Copying patterns from big tech without matching scale | Design for your actual scale, not Netflix's |

---

## How to Apply

### During Brainstorming / Planning
1. Identify the core problem (extensibility? testability? performance? team boundaries?)
2. Check this guide for candidate patterns
3. Evaluate each against the Decision Flow (Section 2)
4. Present trade-offs to Dorian with a clear recommendation

### During Code Review
1. Check if applied patterns are justified (not over-engineered)
2. Scan for anti-patterns in the checklist above
3. Verify invariants from CLAUDE.md are not violated (layered architecture, SOLID, no-any)

### During Refactoring
1. Identify the anti-pattern causing pain
2. Choose the minimum pattern that resolves it
3. Refactor incrementally — don't rewrite entire module at once

---

## Key Reminders

- **CLAUDE.md invariants always apply**: Layered architecture, SOLID, Schema-First, no-any, etc.
- **This guide is contextual**: Patterns here are recommendations, not mandates. The right choice depends on the specific problem, scale, and team
- **When in doubt, choose simplicity**: Three similar lines of code is better than a premature abstraction
- **Dorian's domain is data platforms**: Patterns related to metadata management, ETL, data lineage, and OLAP have extra relevance
