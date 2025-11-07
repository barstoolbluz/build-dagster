# Dagster Runtime Requirements

**Package**: dagster-complete 1.12.0
**Built with**: Nix + Flox

---

## Required Environment Variables

### DAGSTER_HOME (Required)

Dagster requires the `DAGSTER_HOME` environment variable to be set for any operations beyond `--version` and `--help`.

**Setup**:
```bash
# Create directory
export DAGSTER_HOME=$HOME/.dagster
mkdir -p $DAGSTER_HOME

# Set restrictive permissions (recommended)
chmod 700 $DAGSTER_HOME
```

**Important**: Do NOT use world-readable directories like `/tmp/dagster` in production. Use `$HOME/.dagster` or another secure location.

---

## Quick Start

### 1. Set DAGSTER_HOME

```bash
export DAGSTER_HOME=$HOME/.dagster
mkdir -p $DAGSTER_HOME
```

### 2. Verify Installation

```bash
dagster --version
# Output: dagster, version 1.12.0

dagster instance info
# Shows instance configuration
```

### 3. Create Your First Project

```bash
# Create a new Dagster project
dagster project scaffold --name my-dagster-project
cd my-dagster-project
```

### 4. Run Development Server

```bash
# Start the Dagster UI
dagster dev

# Access at: http://localhost:3000
```

---

## Configuration File (Optional)

Create `$DAGSTER_HOME/dagster.yaml` to customize your instance:

```yaml
# Minimal configuration (SQLite for development)
run_storage:
  module: dagster._core.storage.runs
  class: SqliteRunStorage
  config:
    base_dir: $DAGSTER_HOME/history

event_log_storage:
  module: dagster._core.storage.event_log
  class: SqliteEventLogStorage
  config:
    base_dir: $DAGSTER_HOME/history

schedule_storage:
  module: dagster._core.storage.schedules
  class: SqliteScheduleStorage
  config:
    base_dir: $DAGSTER_HOME/schedules

local_artifact_storage:
  module: dagster._core.storage.root
  class: LocalArtifactStorage
  config:
    base_dir: $DAGSTER_HOME/storage
```

**If no `dagster.yaml` exists**: Dagster will use sensible defaults with SQLite storage.

---

## Available Commands

All 5 Dagster CLIs are available:

| Command | Purpose |
|---------|---------|
| `dagster` | Main CLI for project management, asset operations |
| `dagster-daemon` | Background daemon for schedules and sensors |
| `dagster-graphql` | GraphQL API server |
| `dagster-webserver` | Web UI (production mode) |
| `dagster-webserver-debug` | Web UI (debug mode with auto-reload) |

---

## Common Operations

### View Help

```bash
dagster --help           # Main CLI help
dagster asset --help     # Asset commands
dagster run --help       # Run commands
```

### Run Development Server

```bash
# Start everything (webserver + daemon)
dagster dev

# Custom port
dagster dev --port 3001

# Custom host (allow external connections)
dagster dev --host 0.0.0.0 --port 3000
```

### Start Daemon (Production)

```bash
# Start background daemon for schedules/sensors
dagster-daemon run
```

### Launch Web UI (Production)

```bash
# Production webserver
dagster-webserver --port 3000

# Debug mode with auto-reload
dagster-webserver-debug --port 3000
```

---

## Storage Backends

### SQLite (Default - Development)

- **Pros**: No setup required, works out of the box
- **Cons**: Single-user only, not for production
- **Use for**: Local development, testing

### PostgreSQL (Recommended - Production)

Update `$DAGSTER_HOME/dagster.yaml`:

```yaml
run_storage:
  module: dagster_postgres
  class: PostgresRunStorage
  config:
    postgres_url: postgresql://user:password@localhost:5432/dagster

event_log_storage:
  module: dagster_postgres
  class: PostgresEventLogStorage
  config:
    postgres_url: postgresql://user:password@localhost:5432/dagster

schedule_storage:
  module: dagster_postgres
  class: PostgresScheduleStorage
  config:
    postgres_url: postgresql://user:password@localhost:5432/dagster
```

**Note**: Requires `dagster-postgres` integration (not included, install separately)

---

## Security Best Practices

### 1. Protect DAGSTER_HOME

```bash
# Use secure directory
export DAGSTER_HOME=$HOME/.dagster
chmod 700 $DAGSTER_HOME

# Don't use /tmp for production!
# BAD:  export DAGSTER_HOME=/tmp/dagster
# GOOD: export DAGSTER_HOME=$HOME/.dagster
```

### 2. Secure Configuration Files

```bash
# Protect dagster.yaml (may contain credentials)
chmod 600 $DAGSTER_HOME/dagster.yaml
```

### 3. Use Environment Variables for Secrets

Instead of storing secrets in `dagster.yaml`:

```bash
# Set environment variables
export DB_PASSWORD="secret"

# Reference in dagster.yaml
postgres_url: postgresql://user:${DB_PASSWORD}@localhost/dagster
```

Or use Dagster's environment variable syntax:

```yaml
postgres_url:
  env: DATABASE_URL
```

---

## Troubleshooting

### "DAGSTER_HOME is not set"

```bash
# Set and persist in your shell profile
echo 'export DAGSTER_HOME=$HOME/.dagster' >> ~/.bashrc
source ~/.bashrc
mkdir -p $DAGSTER_HOME
```

### "ModuleNotFoundError" Errors

All required dependencies are included in this build. If you see missing modules:
1. Verify you're using the correct `dagster` binary
2. Check that you didn't mix installations (pip + Nix)

### "database is locked" (SQLite)

SQLite is single-user. For multi-user access:
- Use PostgreSQL instead
- Or ensure only one dagster process runs at a time

### "Address already in use" (Port Conflicts)

```bash
# Use different port
dagster dev --port 3001

# Or kill existing process
lsof -ti:3000 | xargs kill
```

### Permission Errors

```bash
# Fix DAGSTER_HOME permissions
chmod 700 $DAGSTER_HOME
chmod 600 $DAGSTER_HOME/dagster.yaml  # if it exists
```

---

## Platform Support

This build is tested on:
- ✅ x86_64-linux (Intel/AMD Linux)
- ✅ aarch64-linux (ARM Linux, Raspberry Pi)

Should also work on:
- ✅ x86_64-darwin (Intel macOS)
- ✅ aarch64-darwin (Apple Silicon M1/M2/M3)

Not supported:
- ❌ Windows native (use WSL2 instead)

---

## What's Included

This complete build includes all core Dagster components:

| Package | Purpose |
|---------|---------|
| **dagster-shared** | Internal utilities |
| **dagster-pipes** | Pipeline communication |
| **dagster** | Core orchestration platform |
| **dagster-graphql** | GraphQL API |
| **dagster-webserver** | Web UI |

**Total closure size**: ~411 MB (includes Python 3.12 + all dependencies)

---

## Integration Packages (Not Included)

For cloud providers, databases, or other integrations:

| Integration | Install Command |
|-------------|----------------|
| PostgreSQL | `pip install dagster-postgres` |
| AWS | `pip install dagster-aws` |
| GCP | `pip install dagster-gcp` |
| Snowflake | `pip install dagster-snowflake` |
| dbt | `pip install dagster-dbt` |
| Docker | `pip install dagster-docker` |

See: https://docs.dagster.io/integrations

---

## Next Steps

1. **Learn Dagster**: https://docs.dagster.io/tutorial
2. **Example Projects**: https://github.com/dagster-io/dagster/tree/master/examples
3. **Community**: https://dagster.io/slack

---

## Version Information

- **Dagster Version**: 1.12.0
- **Python Version**: 3.12
- **Build Type**: Nix + Flox
- **Source**: https://github.com/dagster-io/dagster/tree/1.12.0

---

## Support & Issues

**For Dagster issues**: https://github.com/dagster-io/dagster/issues
**For Nix build issues**: Check build documentation in this repository

---

*Built with Nix for reproducible, isolated Python environments*
*Last updated: 2025-11-06*
