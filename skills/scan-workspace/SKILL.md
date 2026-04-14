---
name: scan-workspace
description: "Scan all projects in current working directory to build comprehensive work context indexes and save to Global Memory. Generates project map, route index, DB schema index, API call chains, data flow mappings, and git branch info. Use when user says: 扫描项目, 构建上下文, 扫描工作区, scan workspace, build context, rebuild context, 重新扫描, update workspace index."
user-invocable: true
---

<!--
input: 当前工作目录（包含多个项目子目录）
output: Global Memory 文件（项目地图、路由索引、表结构、API 链路、数据流）
pos: 手动触发，用于构建/更新工作上下文
-->

# Scan Workspace - 工作上下文构建

> 扫描当前目录下所有项目，生成全套上下文索引，沉淀到 Global Memory。扫完之后任意目录开 session 都能零上下文直接干活。

## 使用方式

在包含所有项目的根目录下执行 `/scan-workspace`。可选参数：
- `/scan-workspace` — 全量扫描当前目录
- `/scan-workspace project-name` — 只扫描指定项目（增量更新）

## 扫描流程

### Phase 1: 项目发现

扫描当前目录下所有子目录，识别项目标识文件：
- `package.json` → Node.js / 前端项目
- `go.mod` → Go 项目
- `pom.xml` / `build.gradle` → Java 项目
- `requirements.txt` / `pyproject.toml` → Python 项目
- `Cargo.toml` → Rust 项目

**对每个项目记录：**
- 项目名（目录名 + package.json name）
- 绝对路径
- 技术栈（框架、语言、主要依赖）
- Git 信息：当前分支、活跃分支列表（最近 30 天有 commit 的分支）、最近 5 条 commit 摘要

### Phase 2: 项目深度扫描

对每个项目执行以下扫描（使用 Agent 工具并行处理多个项目）：

#### 2a. 模块结构
- 读取 src/ 目录结构，识别模块划分
- 提取每个模块的职责（从目录名、index 文件、README 推断）

#### 2b. 路由 → 组件映射（前端项目）
- 查找路由定义文件（`router.ts`、`routes.tsx`、`pages/` 目录、`app/` 目录）
- 建立 URL path → 组件文件路径 → 所属模块 的映射
- 记录页面标题/菜单文案（用于截图匹配）
- **微前端场景**：检测 qiankun/garfish/wujie 等微前端框架的注册配置，记录主应用 + 各子应用的挂载规则（`activeRule`、路由前缀、入口地址），建立子应用路由与宿主路由的映射关系

#### 2c. API 端点（后端项目 / BFF 层）
- 查找 controller / router 定义
- 提取：HTTP method + path + handler 函数位置 + 请求/响应类型
- 识别中间件链（auth、权限校验等）

#### 2d. 数据库表结构
- 查找 ORM schema 定义（Drizzle schema.ts、TypeORM entity、Sequelize model、GORM struct、migration 文件）
- 提取：表名、字段、类型、注释、外键关系、索引
- 识别表间关联关系（FK、join 查询、业务级关联）
- 标注哪个模块/service 操作哪张表（读/写方向）

#### 2e. 跨项目 API 调用
- 搜索 HTTP 客户端调用（axios、fetch、got、http.Get 等）
- 提取目标服务地址/域名 + 接口路径
- 与已扫描项目的 API 端点做交叉匹配，建立调用链
- **环境配置文件**：扫描项目中的配置文件（`config/`、`env/`、`settings/`、`.env.*` 等）提取服务地址映射。本地代码一般是 dev/test 环境配置，生产环境地址在 remote 平台——如果遇到需要生产地址才能确认的调用关系，标记为"待确认"并向用户询问

#### 2f. 私有 npm 包依赖
- 扫描 `package.json` 中的 dependencies，识别内部私有包（`@company/*`、非 public registry 的包）
- 追踪私有包的源码位置（可能在同一 workspace 的其他目录）
- 建立包级别的依赖关系图：哪些项目依赖了哪些内部包，包提供了什么能力

#### 2g. Git 上下文
- **当前分支**：分支名、与 main/master/develop 的 diff stat（改了哪些文件、多少行）
- **活跃分支**（最近 30 天有 commit）：分支名 + 大致改动范围（从 commit message 和 diff stat 推断）
- **最近 20 条 commit**：摘要，用于理解近期工作方向
- **默认只深度扫描当前分支的代码**。其他分支只记录元信息（名称、最近 commit、改动范围），不切换分支读代码——避免影响工作区状态。如果用户需要扫描特定分支的完整代码，使用 `git show {branch}:{file}` 按需读取，不做 checkout

### Phase 3: 交叉分析

- **API 调用链路图**：项目 A 的哪个模块调用了项目 B 的哪个接口
- **共享表分析**：多个项目操作同一张表时，标注各自的读写方向
- **数据流向**：从 API 调用链 + 表操作方向，推导数据的完整流转路径
- **npm 包依赖图**：哪些项目共享了内部包，包的变更会影响哪些下游项目
- **微前端拓扑**：主应用与子应用的挂载关系、路由分配、共享依赖

### Phase 4: 生成项目级 Spec 文件

对每个扫描到的项目，在项目根目录生成 `.claude/spec.md`，包含该项目的**完整详情**：

```markdown
# {项目名} - Project Spec

> 由 /scan-workspace 自动生成，上次扫描：{日期}

## 项目概览
- 技术栈、框架版本、核心依赖
- 业务定位（从代码推断，可能需要人工补充）

## 模块结构
- 每个模块的职责、入口文件、核心组件/服务

## 路由表（前端项目）
- 完整的 URL → 组件 → 页面标题映射
- 微前端子应用挂载规则（如适用）

## API 端点（后端项目）
- 完整的接口清单：method + path + handler + 请求/响应类型

## 数据库表结构
- 该项目涉及的所有表的**完整字段定义**（不是索引摘要）
- 表间关联关系、索引、约束
- 每张表被哪个 service/module 操作（读/写方向）

## 跨项目依赖
- 该项目调用了哪些外部服务的接口
- 哪些外部服务调用了该项目的接口
- 依赖的内部 npm 包

## Git 状态
- 当前分支、活跃分支、近期改动方向
```

**同时确保 `.claude/` 目录被 gitignore**：
- 检查项目根目录的 `.gitignore` 是否已包含 `.claude/`
- 如果没有，追加 `.claude/` 到 `.gitignore`（不要覆盖已有内容）
- 如果项目没有 `.gitignore`，创建一个并写入 `.claude/`

**Spec vs Memory 的分工**：
- **Spec（项目级）**：完整详情，进入项目目录后直接可用，不需要再扫代码
- **Memory（全局）**：索引摘要，在任意目录下快速定位"去哪个项目找"

### Phase 5: 生成 Global Memory 文件

将扫描结果写入 Global Memory（`~/.claude/projects/{project-path}/memory/`），生成以下文件：

#### `work_domain_map.md`
```markdown
---
name: work-domain-map
description: 所有项目的业务定位、路径、技术栈、模块结构速查
type: reference
---

| 项目 | 路径 | 业务定位 | 技术栈 | 核心模块 | 当前分支 |
|------|------|---------|--------|---------|---------|
| ... | ... | ... | ... | ... | ... |
```

#### `work_route_index.md`
```markdown
---
name: work-route-index
description: 所有前端项目的 URL → 组件 → 模块映射，用于从截图/URL 定位代码
type: reference
---

| URL Pattern | 页面标题 | 组件路径 | 所属项目 | 所属模块 |
|------------|---------|---------|---------|---------|
| ... | ... | ... | ... | ... |
```

#### `work_db_schemas.md`
```markdown
---
name: work-db-schemas
description: 所有项目的数据库表结构索引，含字段、关联关系、操作方向
type: reference
---

## {数据库名}

### {表名}
- **用途**: ...
- **操作方**: project-a/module-x (读写), project-b/module-y (只读)
- **关键字段**: field1 (类型, 说明), field2 (类型, 说明)
- **关联**: FK → other_table.id, 业务关联 → another_table via field_name
```

#### `work_api_chains.md`
```markdown
---
name: work-api-chains
description: 跨项目 API 调用链路，含调用方、被调方、接口路径、数据流向
type: reference
---

| 调用方 (项目/模块) | → | 被调方 (项目/接口) | 用途 | 数据方向 |
|-------------------|---|-------------------|------|---------|
| ... | → | ... | ... | ... |
```

#### `work_git_context.md`
```markdown
---
name: work-git-context
description: 各项目 Git 分支状态和近期工作方向
type: reference
---

## {项目名}
- **当前分支**: feature/xxx
- **活跃分支**: feature/a (元数据重构), fix/b (查询性能)
- **近期方向**: 最近在做 xxx
```

### Phase 6: 更新 MEMORY.md 索引

在 MEMORY.md 中添加/更新以下条目：

```markdown
## Work Context（由 /scan-workspace 生成）
- [work_domain_map.md](work_domain_map.md) — 项目地图：业务定位、路径、技术栈
- [work_route_index.md](work_route_index.md) — 路由索引：URL → 组件 → 模块
- [work_db_schemas.md](work_db_schemas.md) — 表结构索引：字段、关联、操作方
- [work_api_chains.md](work_api_chains.md) — 跨项目 API 调用链路
- [work_git_context.md](work_git_context.md) — Git 分支状态和近期工作方向
```

### Phase 7: 扫描报告

输出简要扫描报告：
- 扫描了几个项目，生成了几个 spec 文件
- 识别了多少路由、多少表、多少跨项目调用
- **需要人工补充的内容**（无法从代码推断的业务语义，标红提示）
- 各项目 `.gitignore` 更新情况
- 建议后续操作

## 增量更新

指定项目名时只重新扫描该项目，更新对应 memory 文件中的相关条目，不影响其他项目的记录。

## 注意事项

- Memory 文件是**索引级别**，不是全量代码。详细信息通过索引定位后去读源文件
- 表结构如果过多（>50 张表），按模块分组，只索引表名和一句话用途，详细字段留给按需查询
- 扫描结果是**时间快照**，项目有大改动后需要重新执行
- 如果某个项目的业务定位无法从代码推断，在报告中标出，等用户补充后更新
