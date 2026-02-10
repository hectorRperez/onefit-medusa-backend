## Compatibility

This starter is compatible with versions >= 2 of `@medusajs/medusa`. 

Node 20+ is mandatory

## What is Medusa

Medusa is a set of commerce modules and tools that allow you to build rich, reliable, and performant commerce applications without reinventing core commerce logic. The modules can be customized and used to build advanced ecommerce stores, marketplaces, or any product that needs foundational commerce primitives. All modules are open-source and freely available on npm.

Learn more about [Medusa’s architecture](https://docs.medusajs.com/learn/introduction/architecture) and [commerce modules](https://docs.medusajs.com/learn/fundamentals/modules/commerce-modules) in the Docs.

## Getting Started

This document summarizes everything important learned during the installation and launch of Medusa using Docker, focusing on avoiding common mistakes, understanding why things are done, and getting the project ready for production.

### Objective of the documentation

- Have a quick reference for future installations
- Avoid repeating common mistakes
- Understand what's mandatory, what's only for development, and what changes in production
- Serve as internal project documentation

### Key concepts to understand beforehand

Medusa is a standalone backend

- Medusa is NOT a frontend.
- It runs as a headless backend.
- The frontend (Next.js, etc.) connects via API.

### Medusa Basic Architecture

- Modules → Data owners
- Data Models → Internal structure of each module
- Module Links → Relationships between modules (no foreign keys)
- Queries → Data retrieval between modules
- Services → Business logic
- Workflows → Orchestration (order creation, payments, etc.)
- API Routes → HTTP entry points

### start.sh: the heart of the boot

1. ❌ Common mistake
    - Running seed without using exec causes a restart loop.
2. ✅ Correct version of start.sh

```
#!/bin/sh
set -e


echo "Running database migrations..."
npx medusa db:migrate


echo "Starting Medusa development server..."
exec npm run dev

```

3. Important rules
   - ❌ DO NOT run seed on every boot
   - ✅ The seed is executed only once, manually.
   - ✅ exec is required to prevent Docker from restarting the container

### Data seed

1. ❌ Common mistake
    - The seed is NOT idempotent
    - Running it more than once breaks the boot process

2. ✅ Correct form
    ```
    docker exec -it medusa_backend npm run seed
    ```
    Only the first time.

### Dockerfile (DEV)

```
# Development Dockerfile for Medusa
FROM node:20-alpine

# Set working directory
WORKDIR /server

# Copy package files and npm config
COPY package.json package-lock.json ./

# Install all dependencies using npm
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Expose the port Medusa runs on
EXPOSE 9000 5173

# Start with migrations and then the development server
ENTRYPOINT ["./start.sh"]
```

Notes:
- Node.js 20+ is required.
- Using /server avoids conflicts with the admin.

### Dependencies (npm vs yarn)

Problem
 - The repo includes yarn.lock
 - If you use npm → there's a conflict
Solution

```
npm install --legacy-peer-deps
```
This generates package-lock.json and aligns Docker + local.

### Environment variables (.env)
Why do they exist?
- Separate code and configuration
- Avoid hardcoding secrets
- Allow DEV/PROD without changing code

### SSL and database (DEV vs PROD)

Problem?

- Postgres in Docker does NOT use SSL
- Medusa attempts to use SSL by default

*Correct solution in medusa-config.ts*

```
import { loadEnv, defineConfig } from "@medusajs/framework/utils"

loadEnv(process.env.NODE_ENV || "development", process.cwd())

const isProd = process.env.NODE_ENV === "production"

module.exports = defineConfig({
    projectConfig: {
        databaseUrl: process.env.DATABASE_URL,
        
        databaseDriverOptions: isProd
            ? {
                ssl: {
                    rejectUnauthorized: false,
                },
            }
            : {
                ssl: false,
                sslmode: "disable",
            },

        http: {
            storeCors: process.env.STORE_CORS!,
            adminCors: process.env.ADMIN_CORS!,
            authCors: process.env.AUTH_CORS!,
            jwtSecret: process.env.JWT_SECRET || "supersecret",
            cookieSecret: process.env.COOKIE_SECRET || "supersecret",
        },
    },
})
```

Golden Rule
- ❌ Never disable SSL in production
- ✅ Use Node.env to change behavior

### Medusa Admin + Vite (Docker)

Problem?

- Vite doesn't work properly in Docker by default.
- HMR and WebSocket fail.

Solution? 

*Configure Vite within medusa-config.ts:*

```
admin: {
    vite: () => ({
        server: {
            host: "0.0.0.0",
            allowedHosts: ["localhost", "127.0.0.1"],
            
            hmr: {
                port: 5173,
                clientPort: 5173,
            },
        },
    }),
},
```

This is for DEV only.

### Create an Admin user in Medusa

```
docker exec -it medusa_backend npx medusa user \
  -e admin@onefit.com \
  -p supersecret
```
