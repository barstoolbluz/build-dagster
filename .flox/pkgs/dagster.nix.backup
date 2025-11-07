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

  # Create a proper Python environment with all packages
  dagsterPythonEnv = python312.withPackages (ps: [
    dagster-shared
    dagster-pipes
    dagster
    dagster-graphql
    dagster-webserver
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
