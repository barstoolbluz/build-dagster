# Dagster orchestration platform - all packages in a single closure with proper Python environment
{ python312
, python312Packages
, fetchFromGitHub
, fetchPypi
, symlinkJoin
, makeWrapper
}:

let
  # Fetch source from upstream GitHub (stable release 1.12.0)
  dagster-src = fetchFromGitHub {
    owner = "dagster-io";
    repo = "dagster";
    rev = "1.12.0";
    hash = "sha256-MBI7vTTIrFk63hd6u6BL8HrOW5e1b1XGBCkmolSkLro=";
  };

  # Build dagster-shared (internal utilities)
  dagster-shared = python312Packages.buildPythonPackage {
    pname = "dagster-shared";
    version = "1.12.0";

    src = dagster-src;
    sourceRoot = "source/python_modules/libraries/dagster-shared";

    format = "setuptools";

    nativeBuildInputs = with python312Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with python312Packages; [
      packaging
      pyyaml
      platformdirs
      pydantic
      typing-extensions
      tomlkit
    ];

    doCheck = false;
    pythonImportsCheck = [ "dagster_shared" ];

    meta = {
      description = "Dagster shared utilities";
      homepage = "https://dagster.io";
    };
  };

  # Build dagster-pipes (pipeline communication)
  dagster-pipes = python312Packages.buildPythonPackage {
    pname = "dagster-pipes";
    version = "1.12.0";

    src = dagster-src;
    sourceRoot = "source/python_modules/dagster-pipes";

    format = "setuptools";

    nativeBuildInputs = with python312Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = [ dagster-shared ];

    doCheck = false;
    pythonImportsCheck = [ "dagster_pipes" ];

    meta = {
      description = "Dagster pipes for data pipeline communication";
      homepage = "https://dagster.io";
    };
  };

  # Build main dagster package
  dagster = python312Packages.buildPythonPackage {
    pname = "dagster";
    version = "1.12.0";

    src = dagster-src;
    sourceRoot = "source/python_modules/dagster";

    format = "setuptools";

    nativeBuildInputs = with python312Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with python312Packages; [
      # Core dependencies
      alembic
      click
      coloredlogs
      jinja2
      grpcio
      grpcio-health-checking
      protobuf
      python-dotenv
      pytz
      requests
      setuptools
      six
      tabulate
      tomli
      tqdm
      tzdata
      structlog
      sqlalchemy
      toposort
      watchdog
      docstring-parser
      rich
      filelock
      pydantic
      # Python 3.12+ specific
      universal-pathlib
      # Expression parsing
      antlr4-python3-runtime
    ] ++ [
      # Internal packages
      dagster-pipes
      dagster-shared
    ];

    doCheck = false;
    pythonImportsCheck = [ "dagster" ];

    meta = {
      description = "The orchestration platform for data assets";
      homepage = "https://dagster.io";
    };
  };

  # Build dagster-graphql (GraphQL API)
  dagster-graphql = python312Packages.buildPythonPackage {
    pname = "dagster-graphql";
    version = "1.12.0";

    src = dagster-src;
    sourceRoot = "source/python_modules/dagster-graphql";

    format = "setuptools";

    nativeBuildInputs = with python312Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with python312Packages; [
      dagster
      graphene
      gql
      requests
      requests-toolbelt
      starlette
    ];

    doCheck = false;
    pythonImportsCheck = [ "dagster_graphql" ];

    meta = {
      description = "Dagster GraphQL API";
      homepage = "https://dagster.io";
    };
  };

  # Build dagster-webserver (Web UI)
  # Note: Fetched from PyPI instead of GitHub because PyPI wheel includes pre-built webapp assets
  dagster-webserver = python312Packages.buildPythonPackage {
    pname = "dagster-webserver";
    version = "1.12.0";

    src = fetchPypi {
      pname = "dagster_webserver";
      version = "1.12.0";
      hash = "sha256-X11EvG1ybjx5OhLjpWsOFv6KMoCBkr1yPbMwLU9ksG4=";
    };

    format = "setuptools";

    nativeBuildInputs = with python312Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with python312Packages; [
      dagster
      dagster-graphql
      click
      starlette
      uvicorn
    ];

    doCheck = false;
    pythonImportsCheck = [ "dagster_webserver" ];

    meta = {
      description = "Dagster web server and UI";
      homepage = "https://dagster.io";
    };
  };

  # Build dagster-postgres (PostgreSQL integration)
  dagster-postgres = python312Packages.buildPythonPackage {
    pname = "dagster-postgres";
    version = "1.12.0";

    src = dagster-src;
    sourceRoot = "source/python_modules/libraries/dagster-postgres";

    format = "setuptools";

    nativeBuildInputs = with python312Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with python312Packages; [
      dagster
      psycopg2
    ];

    doCheck = false;
    pythonImportsCheck = [ "dagster_postgres" ];

    meta = {
      description = "Dagster PostgreSQL storage integration";
      homepage = "https://dagster.io";
    };
  };

  # Create a proper Python environment with all packages
  dagsterPythonEnv = python312.withPackages (ps: [
    dagster-shared
    dagster-pipes
    dagster
    dagster-graphql
    dagster-webserver
    dagster-postgres
  ]);

in
# Combine Python environment and binaries into a single closure
symlinkJoin {
  name = "dagster-1.12.0";
  version = "1.12.0";

  paths = [ dagsterPythonEnv ];

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    # Ensure all Dagster CLIs use the proper Python environment
    for bin in $out/bin/dagster*; do
      if [ -f "$bin" ]; then
        wrapProgram "$bin" \
          --prefix PYTHONPATH : "${dagsterPythonEnv}/${python312.sitePackages}"
      fi
    done

    # Create helper scripts for Flox environment initialization

    # dagster-init-config: Generate dagster.yaml configuration
    cat > $out/bin/dagster-init-config << 'INIT_SCRIPT'
#!/usr/bin/env bash
# dagster-init-config - Generate Dagster instance configuration
# This script creates the dagster.yaml file based on environment variables

# Ensure directories exist
mkdir -p "$DAGSTER_HOME" "$DAGSTER_STORAGE_DIR"
chmod 700 "$DAGSTER_HOME"

cat > "$DAGSTER_YAML" << EOF
# Dagster configuration generated by Flox (headless mode)
EOF

if [ "$DAGSTER_STORAGE_TYPE" = "sqlite" ]; then
    cat >> "$DAGSTER_YAML" << EOF

# SQLite Storage (Development)
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
EOF
elif [ "$DAGSTER_STORAGE_TYPE" = "postgres" ] && [ -n "$DAGSTER_POSTGRES_URL" ]; then
    cat >> "$DAGSTER_YAML" << EOF

# PostgreSQL Storage (Production)
run_storage:
  module: dagster_postgres
  class: PostgresRunStorage
  config:
    postgres_url: $DAGSTER_POSTGRES_URL

event_log_storage:
  module: dagster_postgres
  class: PostgresEventLogStorage
  config:
    postgres_url: $DAGSTER_POSTGRES_URL

schedule_storage:
  module: dagster_postgres
  class: PostgresScheduleStorage
  config:
    postgres_url: $DAGSTER_POSTGRES_URL
EOF
fi

cat >> "$DAGSTER_YAML" << EOF

# Local Artifact Storage
local_artifact_storage:
  module: dagster._core.storage.root
  class: LocalArtifactStorage
  config:
    base_dir: $DAGSTER_STORAGE_DIR
EOF

# Add run launcher if specified
if [ -n "$DAGSTER_RUN_LAUNCHER" ]; then
    cat >> "$DAGSTER_YAML" << EOF

# Run Launcher
run_launcher:
  module: dagster._core.launcher
  class: $DAGSTER_RUN_LAUNCHER
  config:
    max_concurrent_runs: $DAGSTER_MAX_CONCURRENT_RUNS
EOF
fi

chmod 644 "$DAGSTER_YAML"
INIT_SCRIPT

    # dagster-welcome: Display welcome message and configuration
    cat > $out/bin/dagster-welcome << 'WELCOME_SCRIPT'
#!/usr/bin/env bash
# dagster-welcome - Display Dagster environment welcome message

echo ""
echo "✅ Dagster environment ready (headless mode)"
echo ""

# Safety warnings
if [ "$DAGSTER_HOME" = "/tmp/dagster" ] || [[ "$DAGSTER_HOME" == /tmp/* ]]; then
    echo "⚠️  WARNING: DAGSTER_HOME in /tmp - DATA LOSS ON REBOOT"
fi
if [ "$DAGSTER_STORAGE_TYPE" = "sqlite" ]; then
    echo "⚠️  INFO: Using SQLite storage - not suitable for production"
fi
if [ "$DAGSTER_HOST" = "0.0.0.0" ]; then
    echo "⚠️  WARNING: Listening on all interfaces - NETWORK EXPOSED"
fi
[ "$DAGSTER_HOME" = "/tmp/dagster" ] || [[ "$DAGSTER_HOME" == /tmp/* ]] || [ "$DAGSTER_STORAGE_TYPE" = "sqlite" ] || [ "$DAGSTER_HOST" = "0.0.0.0" ] && echo ""

echo "Instance:"
echo "  DAGSTER_HOME: ''${DAGSTER_HOME}"
echo "  Config file: ''${DAGSTER_YAML}"
echo ""
echo "Connection:"
echo "  Host: ''${DAGSTER_HOST}:''${DAGSTER_PORT}"
echo "  Web UI: http://''${DAGSTER_HOST}:''${DAGSTER_PORT}"
echo ""
echo "Storage:"
echo "  Type: ''${DAGSTER_STORAGE_TYPE}"
if [ "$DAGSTER_STORAGE_TYPE" = "postgres" ]; then
    echo "  PostgreSQL: ''${DAGSTER_POSTGRES_URL}"
fi
echo "  Artifacts: ''${DAGSTER_STORAGE_DIR}"
echo ""

# PostgreSQL detection and guidance
if command -v postgres >/dev/null 2>&1; then
    echo "PostgreSQL: Available via composition"
    if [ "$DAGSTER_STORAGE_TYPE" = "postgres" ]; then
        echo "  Status: CONFIGURED (Dagster will use PostgreSQL)"
        echo "  ⚠️  Start postgres first: flox services start postgres"
    else
        echo "  Status: Available but not configured (using SQLite)"
        echo "  To use: DAGSTER_STORAGE_TYPE=postgres flox activate"
    fi
    echo ""
fi

echo "Commands:"
echo "  flox activate -s           Start Dagster (webserver + daemon)"
echo "  dagster --version          Show Dagster version"
echo "  dagster instance info      Show instance details"
echo "  dagster-info               Show configuration"
echo "  flox services status       Check service status"
if command -v postgres >/dev/null 2>&1 && [ "$DAGSTER_STORAGE_TYPE" = "postgres" ]; then
    echo "  dagster-with-postgres      Start Dagster with PostgreSQL"
fi
echo ""
WELCOME_SCRIPT

    # dagster-info: Display current configuration (for use as a shell function)
    cat > $out/bin/dagster-info << 'INFO_SCRIPT'
#!/usr/bin/env bash
# dagster-info - Display Dagster configuration details

echo "Dagster (Headless Mode) - Configuration"
echo ""
echo "Instance:"
echo "  DAGSTER_HOME: ''${DAGSTER_HOME}"
echo "  Config file: ''${DAGSTER_YAML}"
echo ""
echo "Connection:"
echo "  Host: ''${DAGSTER_HOST}:''${DAGSTER_PORT}"
echo "  Web UI: http://''${DAGSTER_HOST}:''${DAGSTER_PORT}"
echo ""
echo "Storage:"
echo "  Type: ''${DAGSTER_STORAGE_TYPE}"
if [ "$DAGSTER_STORAGE_TYPE" = "postgres" ] && [ -n "$DAGSTER_POSTGRES_URL" ]; then
    echo "  PostgreSQL: ''${DAGSTER_POSTGRES_URL}"
fi
echo "  Artifacts: ''${DAGSTER_STORAGE_DIR}"
echo ""
echo "Compute:"
if [ -n "$DAGSTER_RUN_LAUNCHER" ]; then
    echo "  Run launcher: ''${DAGSTER_RUN_LAUNCHER}"
else
    echo "  Run launcher: (default)"
fi
echo "  Max concurrent runs: ''${DAGSTER_MAX_CONCURRENT_RUNS}"
echo ""
if [ -n "$DAGSTER_CODE_LOCATION_NAME" ] || [ -n "$DAGSTER_MODULE_NAME" ]; then
    echo "Code Location:"
    [ -n "$DAGSTER_CODE_LOCATION_NAME" ] && echo "  Name: ''${DAGSTER_CODE_LOCATION_NAME}"
    [ -n "$DAGSTER_MODULE_NAME" ] && echo "  Module: ''${DAGSTER_MODULE_NAME}"
    [ -n "$DAGSTER_WORKING_DIRECTORY" ] && echo "  Working dir: ''${DAGSTER_WORKING_DIRECTORY}"
    echo ""
fi
echo "Commands:"
echo "  dagster --version                    Show Dagster version"
echo "  dagster instance info                Show instance details"
echo "  flox activate -s                     Start Dagster services"
echo "  flox services status                 Check service status"
echo "  flox services logs dagster-webserver View webserver logs"
echo "  flox services logs dagster-daemon    View daemon logs"
INFO_SCRIPT

    # dagster-with-postgres: Start Dagster with PostgreSQL backend
    cat > $out/bin/dagster-with-postgres << 'POSTGRES_SCRIPT'
#!/usr/bin/env bash
# dagster-with-postgres - Start Dagster with PostgreSQL backend

# Ensure we're in a flox environment
if [ -z "$FLOX_ENV" ]; then
    echo "❌ This script must be run inside a flox environment"
    echo "   Try: flox activate"
    exit 1
fi

# Check if postgres command exists
if ! command -v postgres >/dev/null 2>&1; then
    echo "❌ PostgreSQL not found"
    echo "   This environment needs to include postgres-headless"
    exit 1
fi

# Set postgres storage type
export DAGSTER_STORAGE_TYPE=postgres
export PGDATABASE="''${PGDATABASE:-dagster}"

# Auto-generate connection URL
export DAGSTER_POSTGRES_URL="postgresql://''${PGUSER}:''${PGPASSWORD}@''${PGHOSTADDR:-127.0.0.1}:''${PGPORT:-15432}/''${PGDATABASE}"

echo "Starting PostgreSQL..."
flox services start postgres

# Wait for postgres to be ready
echo "Waiting for PostgreSQL to be ready..."
for i in {1..10}; do
    if pg_isready -h "''${PGHOSTADDR:-127.0.0.1}" -p "''${PGPORT:-15432}" >/dev/null 2>&1; then
        echo "✅ PostgreSQL is ready"
        break
    fi
    sleep 1
done

echo "Starting Dagster services..."
flox services start dagster-webserver
flox services start dagster-daemon

sleep 2

echo ""
echo "✅ Dagster with PostgreSQL is running"
echo ""
echo "Web UI: http://''${DAGSTER_HOST}:''${DAGSTER_PORT}"
echo "PostgreSQL: ''${PGHOSTADDR}:''${PGPORT}/''${PGDATABASE}"
echo ""
echo "Commands:"
echo "  flox services status                    Check all services"
echo "  flox services logs dagster-webserver    View webserver logs"
echo "  flox services logs postgres             View postgres logs"
echo "  dagster-info                            Show Dagster config"
echo "  postgres-info                           Show PostgreSQL config"
POSTGRES_SCRIPT

    # Make all helper scripts executable
    chmod +x $out/bin/dagster-init-config
    chmod +x $out/bin/dagster-welcome
    chmod +x $out/bin/dagster-info
    chmod +x $out/bin/dagster-with-postgres
  '';

  meta = {
    description = "Dagster orchestration platform with all components";
    homepage = "https://dagster.io";
    longDescription = ''
      Complete Dagster orchestration platform including:
      - dagster-shared (utilities)
      - dagster-pipes (pipeline communication)
      - dagster (core platform)
      - dagster-graphql (GraphQL API)
      - dagster-webserver (web UI with pre-built assets)

      Provides all CLIs: dagster, dagster-daemon, dagster-graphql,
      dagster-webserver, dagster-webserver-debug

      Built as a proper Python environment where all packages can import each other.
    '';
  };
}
