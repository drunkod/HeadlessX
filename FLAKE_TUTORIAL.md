# HeadlessX Flake Tutorial

This flake gives you reproducible commands for cloning, installing dependencies, running PostgreSQL, setting up Prisma DB, and starting development.

## Prerequisites

- Nix with flakes enabled
- Internet access for fetching flake inputs and npm packages

## 1) Enter the dev shell (optional)

```bash
nix develop
```

The shell includes Node.js 22, pnpm, git, PostgreSQL 16, and native runtime libraries.

## 2) Clone the repository

Clone into the current empty directory:

```bash
nix run .#clone -- https://github.com/saifyxpro/HeadlessX
```

Or clone into a folder:

```bash
nix run .#clone -- https://github.com/saifyxpro/HeadlessX HeadlessX
cd HeadlessX
```

## 3) Create environment file

```bash
nix run .#env
```

This creates `backend/.env` from `.env.example` if it does not exist.

## 4) Start local PostgreSQL

```bash
nix run .#postgres-start
```

Default connection produced by this command:

```text
postgresql://postgres@127.0.0.1:5432/headlessx
```

You can customize with environment variables:

- `POSTGRES_DATA_DIR` (default: `.postgres`)
- `POSTGRES_PORT` (default: `5432`)
- `POSTGRES_USER` (default: `postgres`)
- `POSTGRES_DB` (default: `headlessx`)

Example:

```bash
POSTGRES_PORT=55432 POSTGRES_DATA_DIR=.pgdata nix run .#postgres-start
```

## 5) Install dependencies and push Prisma schema

```bash
nix run .#install-db
```

This runs:

1. `pnpm install`
2. `pnpm db:push`

It requires `DATABASE_URL` in `backend/.env` to be set and non-empty.

## One-command setup with local PostgreSQL

If you want install + DB setup with local PostgreSQL managed for you:

```bash
nix run .#setup-install-db
```

What it does:

1. Creates `backend/.env` if missing
2. Initializes/starts PostgreSQL locally
3. Sets `DATABASE_URL` to local PostgreSQL if missing/empty
4. Runs `pnpm install`
5. Runs `pnpm db:push`

## Full project setup command

```bash
nix run .#setup -- https://github.com/saifyxpro/HeadlessX
```

This command handles clone + install + model fetch + DB push (it expects `DATABASE_URL` to exist in `backend/.env`).

## Start development server

```bash
nix run .#dev
```

Or directly:

```bash
pnpm dev
```

## Stop local PostgreSQL

```bash
nix run .#postgres-stop
```

## Command reference

- `nix run .#clone -- <repo-url> [dir]`
- `nix run .#env`
- `nix run .#deps`
- `nix run .#models`
- `nix run .#db`
- `nix run .#install-db`
- `nix run .#postgres-start`
- `nix run .#postgres-stop`
- `nix run .#setup-install-db`
- `nix run .#setup -- [repo-url] [dir]`
- `nix run .#dev`

## Troubleshooting

- If `DATABASE_URL is missing or empty in backend/.env`, set `DATABASE_URL` and rerun.
- If PostgreSQL cannot start, check if the port is already in use and try `POSTGRES_PORT=<new-port>`.
- If clone fails in `.` target, use an empty directory or pass a target folder.
