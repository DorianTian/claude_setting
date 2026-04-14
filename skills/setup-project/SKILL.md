---
name: setup-project
description: "Initialize or scaffold a new project. Supports: (1) Frontend: Next.js 16 + React 19 + Tailwind 4 + shadcn/ui; (2) Backend: Koa.js + TypeScript + MySQL; (3) Full-stack: both. All include ESLint + Prettier. Trigger when user asks to create a new project, scaffold a module, init project, or set up the tech stack."
user-invocable: true
---

# Project Scaffolding Skill

Set up a new project with standardized tech stack, code formatting, and linting.

## Arguments

$ARGUMENTS

If no arguments provided, ask the user for:
1. Project name (e.g., `my-app`)
2. Project type: `frontend` | `backend` | `fullstack`
3. Additional options (i18n, monorepo, etc.)

---

## Shared Config (Frontend & Backend)

### Prettier Configuration

All project types share the same Prettier config.

File: `.prettierrc`

```json
{
  "semi": true,
  "singleQuote": true,
  "jsxSingleQuote": false,
  "trailingComma": "all",
  "printWidth": 100,
  "tabWidth": 2,
  "arrowParens": "always",
  "endOfLine": "lf",
  "bracketSpacing": true,
  "bracketSameLine": false,
  "htmlWhitespaceSensitivity": "css",
  "vueIndentScriptAndStyle": false
}
```

> Frontend projects additionally install `prettier-plugin-tailwindcss` and add `plugins: ['prettier-plugin-tailwindcss']`.

File: `.prettierignore`

```
# Dependencies
node_modules/

# Build outputs
.next/
out/
build/
dist/

# Generated
src/generated/

# Lock files
pnpm-lock.yaml

# Assets
*.gif
*.svg
*.png
*.ico
*.ttf
*.webp
*.jpg
*.jpeg

# Snapshots
*.snap

# macOS
.DS_Store

# Claude
.claude/
```

Dev dependencies:
```
prettier eslint-config-prettier
```

### .nvmrc

```
22
```

### .gitignore

```
node_modules
dist
build
.next
.env
.env.*
!.env.example
*.log
.DS_Store
```

---

## Frontend — Next.js

### Tech Stack

| Layer | Choice | Version |
|-------|--------|---------|
| Framework | Next.js (App Router) | 16.x |
| UI Library | React | 19.x |
| Language | TypeScript | 5.x |
| Styling | Tailwind CSS | 4.x |
| Component Library | shadcn/ui | latest |
| Icons | Lucide React | latest |
| Charts | Recharts | 2.x |
| Package Manager | pnpm | 10.x |
| Linting | ESLint + eslint-config-next | 9.x |
| Formatting | Prettier | 3.x |

### Config Files

- `package.json` — scripts: dev/build/start/lint/lint:fix/format/format:check
- `tsconfig.json` — strict, paths `@/*` → `./src/*`, Next.js plugin
- `next.config.ts` — basic config
- `postcss.config.mjs` — `@tailwindcss/postcss`
- `components.json` — shadcn config (CSS variables, neutral theme)

### ESLint (Frontend)

File: `eslint.config.mjs`

```js
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/flatcompat";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({ baseDirectory: __dirname });

const eslintConfig = [
  ...compat.extends("next/core-web-vitals", "next/typescript", "prettier"),
  {
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },
];

export default eslintConfig;
```

Dev dependencies:
```
eslint eslint-config-next @eslint/flatcompat eslint-config-prettier prettier-plugin-tailwindcss
```

### Package.json Scripts (Frontend)

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "format": "prettier --write \"src/**/*.{ts,tsx,js,jsx,json,css,md}\"",
    "format:check": "prettier --check \"src/**/*.{ts,tsx,js,jsx,json,css,md}\""
  }
}
```

### Directory Structure (Frontend)

```
src/
├── app/
│   ├── layout.tsx          # Root layout
│   ├── page.tsx            # Home page
│   └── globals.css         # Tailwind + CSS variables
├── components/
│   ├── layout/             # Layout components (sidebar, shell, etc.)
│   └── ui/                 # shadcn components (installed via CLI)
├── lib/
│   ├── types.ts            # Shared type definitions
│   └── utils.ts            # cn() helper, etc.
└── hooks/                  # Custom React hooks
```

### shadcn/ui Base Components

Minimum set:
```
button card badge tabs table separator avatar dropdown-menu
sidebar sheet scroll-area tooltip input textarea select
checkbox switch label dialog popover command skeleton progress
```

Install via: `pnpm dlx shadcn@latest add <component>`

### Global CSS

Include in `globals.css`:
- Tailwind import (`@import "tailwindcss"`)
- Light/dark theme CSS variables
- Border radius variables
- Font variables

---

## Backend — Koa.js

### Tech Stack

| Layer | Choice | Version |
|-------|--------|---------|
| Framework | Koa.js | 2.x |
| Language | TypeScript | 5.x |
| Runtime | Node.js | 22.x |
| Database | MySQL | 8.0 |
| ORM | Knex.js (query builder) | latest |
| MySQL Driver | mysql2 | latest |
| Auth | jsonwebtoken + bcryptjs | latest |
| Validation | zod | latest |
| Env | dotenv | latest |
| Process Manager | PM2 (production) | latest |
| Linting | ESLint + @typescript-eslint | 9.x |
| Formatting | Prettier | 3.x |
| Build | tsup (or tsc) | latest |
| Dev | tsx (watch mode) | latest |

### Config Files

- `package.json` — scripts: dev/build/start/lint/lint:fix/format/format:check
- `tsconfig.json` — strict, outDir `dist`, rootDir `src`, module `NodeNext`
- `.env.example` — documented env vars template

### tsconfig.json (Backend)

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### ESLint (Backend)

File: `eslint.config.mjs`

```js
import eslint from "@eslint/js";
import tseslint from "typescript-eslint";
import prettier from "eslint-config-prettier";

export default tseslint.config(
  eslint.configs.recommended,
  ...tseslint.configs.recommended,
  prettier,
  {
    rules: {
      "@typescript-eslint/no-explicit-any": "error",
      "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_", varsIgnorePattern: "^_" }],
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },
  {
    ignores: ["dist/", "node_modules/"],
  },
);
```

Dev dependencies:
```
eslint @eslint/js typescript-eslint eslint-config-prettier
```

### Package.json Scripts (Backend)

```json
{
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsup src/index.ts --format esm --dts",
    "start": "node dist/index.js",
    "lint": "eslint src/",
    "lint:fix": "eslint src/ --fix",
    "format": "prettier --write \"src/**/*.{ts,js,json,md}\"",
    "format:check": "prettier --check \"src/**/*.{ts,js,json,md}\"",
    "db:migrate": "knex migrate:latest",
    "db:rollback": "knex migrate:rollback",
    "db:seed": "knex seed:run"
  }
}
```

### Directory Structure (Backend)

```
src/
├── index.ts                # App entry — Koa server bootstrap
├── config/
│   ├── index.ts            # Env config (dotenv + validation)
│   └── database.ts         # Knex config
├── middleware/
│   ├── auth.ts             # JWT authentication
│   ├── error-handler.ts    # Global error handling
│   ├── logger.ts           # Request logging
│   └── validator.ts        # Zod request validation
├── modules/                # Feature modules (domain-driven)
│   ├── auth/
│   │   ├── auth.router.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   └── auth.schema.ts  # Zod schemas
│   ├── tickets/
│   │   ├── tickets.router.ts
│   │   ├── tickets.controller.ts
│   │   ├── tickets.service.ts
│   │   └── tickets.schema.ts
│   └── ...                 # Other modules follow same pattern
├── shared/
│   ├── types.ts            # Shared type definitions
│   ├── constants.ts        # Enums, status maps, etc.
│   └── helpers.ts          # Utility functions
└── database/
    ├── migrations/         # Knex migration files
    └── seeds/              # Seed data
```

### .env.example (Backend)

```env
# Server
PORT=4000
NODE_ENV=development

# Database
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=aix_ops_hub

# JWT
JWT_SECRET=change-me-in-production
JWT_EXPIRES_IN=8h
JWT_REFRESH_EXPIRES_IN=7d

# AI (Claude API)
ANTHROPIC_API_KEY=

# CORS
CORS_ORIGIN=http://localhost:3000
```

### Koa.js Entry Point Pattern

```typescript
import Koa from "koa";
import Router from "@koa/router";
import cors from "@koa/cors";
import bodyParser from "koa-bodyparser";
import { config } from "./config";
import { errorHandler } from "./middleware/error-handler";
import { logger } from "./middleware/logger";

const app = new Koa();

// Middleware
app.use(errorHandler);
app.use(logger);
app.use(cors({ origin: config.corsOrigin }));
app.use(bodyParser());

// Routes
const router = new Router({ prefix: "/api/v1" });
// router.use("/auth", authRouter.routes());
// router.use("/tickets", ticketsRouter.routes());
app.use(router.routes());
app.use(router.allowedMethods());

app.listen(config.port, () => {
  console.warn(`Server running on port ${config.port}`);
});
```

---

## Full-stack Project

For full-stack projects, create a monorepo with two packages:

```
project-root/
├── pnpm-workspace.yaml     # packages: ["packages/*"]
├── package.json             # root workspace scripts
├── .gitignore
├── .prettierrc.yaml         # shared Prettier config
├── .prettierignore
├── .nvmrc
├── packages/
│   ├── web/                 # Frontend (Next.js) — see Frontend section
│   └── api/                 # Backend (Koa.js) — see Backend section
```

Root `package.json` scripts:
```json
{
  "scripts": {
    "dev": "pnpm --parallel --filter './packages/*' dev",
    "build": "pnpm --filter './packages/*' build",
    "lint": "pnpm --filter './packages/*' lint",
    "format": "pnpm --filter './packages/*' format",
    "format:check": "pnpm --filter './packages/*' format:check"
  }
}
```

---

## Post-Scaffold Verification

After scaffolding, verify:
1. `pnpm install` succeeds
2. `pnpm dev` starts without errors (both frontend and backend if full-stack)
3. `pnpm lint` passes
4. `pnpm format:check` passes
5. Frontend: home page renders correctly, shadcn components available
6. Backend: server starts, health check endpoint responds
