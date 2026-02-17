# HeadlessX Flake Tutorial

This flake provides reproducible `nix run` commands for setup, database, dev, build, and production start.

## Prerequisites

- Nix with flakes enabled
- Internet access for flake inputs and npm packages

## Optional: Enter Dev Shell

```bash
nix develop
```

The shell includes Node.js 22, pnpm, git, PostgreSQL 16, Prisma engines, and runtime libs.

## Quick Start (existing repo)

1. Create env file:

```bash
nix run .#env
```

2. Setup local PostgreSQL + install + `db push`:

```bash
POSTGRES_DATA_DIR=.postgres-nix POSTGRES_PORT=55432 nix run .#setup-install-db
```

3. Start development:

```bash
nix run .#dev
```

Or run production mode:

```bash
nix run .#build
nix run .#start
```

## PostgreSQL Commands

Start local PostgreSQL:

```bash
nix run .#postgres-start
```

Stop local PostgreSQL:

```bash
nix run .#postgres-stop
```

Supported env vars:

- `POSTGRES_DATA_DIR` default: `.postgres`
- `POSTGRES_PORT` default: `5432`
- `POSTGRES_USER` default: `postgres`
- `POSTGRES_DB` default: `headlessx`

## Build and Run Commands

Build backend + frontend:

```bash
nix run .#build
```

Start backend + frontend (production):

```bash
nix run .#start
```

Build frontend only:

```bash
nix run .#build-client
```

Start frontend only (production):

```bash
nix run .#start-client
```

Notes:

- `nix run .#start` auto-builds frontend if `frontend/.next/BUILD_ID` is missing.
- `nix run .#start-client` also auto-builds frontend if needed.

## Camoufox on NixOS

This flake now sets `CAMOUFOX_EXECUTABLE_PATH` automatically and links it to:

- preferred path: `/home/alex/Documents/camoufox-browser-nix/result/bin/camoufox-bin`
- fallback path: flake-packaged Camoufox binary

You can override at runtime:

```bash
HEADLESSX_CAMOUFOX_BIN=/path/to/camoufox-bin nix run .#start
```

## Full Command Reference

- `nix run .` (same as `nix run .#setup`)
- `nix run .#setup -- [repo-url] [dir]`
- `nix run .#clone -- <repo-url> [dir]`
- `nix run .#env`
- `nix run .#deps`
- `nix run .#models`
- `nix run .#db`
- `nix run .#install-db`
- `nix run .#postgres-start`
- `nix run .#postgres-stop`
- `nix run .#setup-install-db`
- `nix run .#dev`
- `nix run .#build`
- `nix run .#start`
- `nix run .#build-client`
- `nix run .#start-client`

## Troubleshooting

- If `DATABASE_URL` is missing/empty in `backend/.env`, set it and rerun DB/setup commands.
- If PostgreSQL cannot start, switch port: `POSTGRES_PORT=55432 nix run .#postgres-start`.
- If clone into `.` fails, use an empty directory or pass a target folder.
