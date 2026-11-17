# Medusa local service kit (macOS, Medusa DTC monorepo)

Designed for:

```
~/Projects/medusa-learning/
  package.json
  apps/backend/package.json
  apps/storefront/package.json
```

Ports: backend/admin **8218**, storefront **9900**, PostgreSQL **5432**. Port **9000** is deliberately untouched (PHP-FPM/PhpStorm).

## Install

Extract this archive, then **copy the `scripts/` directory into the project root**, merging with your existing `scripts/` directory. Inspect differences if files already exist.

```bash
cd ~/Projects/medusa-learning
cp scripts/config.env.example scripts/config.env  # only if not already present
chmod +x scripts/*.sh
```

**Important:** The scripts start two apps, but the DTC starter's actual `dev` scripts may differ. Check them first:

```bash
node -p "require('/Users/ccastro/Projects/medusa-learning/apps/backend/package.json').scripts"
node -p "require('/Users/ccastro/Projects/medusa-learning/apps/storefront/package.json').scripts"
```

Edit `scripts/config.env` if needed. `STOREFRONT_START_COMMAND` assumes a Next.js `dev` script that accepts `--port`. If your script uses Turbo or another runner, set an appropriate command (e.g. `npx next dev -p 9900`). If the backend uses `start` instead of `dev`, adjust `BACKEND_START_COMMAND`.

## Environment files

`env-templates/` includes **example snippets**, not your actual local `.env` files. Your existing local credentials cannot be accessed here. **Never overwrite the installer-generated .env files.** Merge only the relevant variables.

- `env-templates/backend.env.example` -> merge into `apps/backend/.env` if that is where your backend loads configuration.
- `env-templates/storefront.env.local.example` -> merge into `apps/storefront/.env.local` if your storefront uses it.
- `env-templates/root.env.example` -> root `.env` is optional.

Inspect actual files **without displaying secrets publicly**:

```bash
find ~/Projects/medusa-learning -maxdepth 3 -name '.env*' -not -path '*/node_modules/*'
grep -R -n -E 'STORE_CORS|ADMIN_CORS|AUTH_CORS|MEDUSA_BACKEND_URL' apps/backend/medusa-config.ts apps/storefront/next.config.* 2>/dev/null || true
```

Backend CORS values must be read by `medusa-config.ts`. If that file hardcodes CORS, edit it instead of relying on `.env` alone. A storefront publishable API key and sales channel may be needed for product requests.

## Commands

```bash
./scripts/start.sh
./scripts/status.sh
./scripts/stop.sh
./scripts/start-postgres.sh
./scripts/stop-postgres.sh  # only when other projects don't need PostgreSQL
```

Logs: `.local-services/backend.log`, `.local-services/storefront.log`. The scripts do not stop anything on port 9000. `stop.sh` targets only processes launched by this manager; PostgreSQL is deliberately left running. `start.sh` checks ports but cannot guarantee readiness; check logs/status after startup.

**If an app is already running outside this manager**, stop it from its own terminal before using `start.sh`; the scripts will refuse to take an occupied port.

## Security

Do not commit `.env`, `.env.local`, or `scripts/config.env` if they contain secrets. `env-templates` contains no real secrets.
