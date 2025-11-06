# Complete Dagster build - all packages in a single closure
{ python312Packages
, fetchFromGitHub
, runCommand
, buildEnv
}:

let
  # Fetch source from upstream GitHub
  dagster-src = fetchFromGitHub {
    owner = "dagster-io";
    repo = "dagster";
    rev = "master";
    hash = "sha256-hR3QRm5ihtTcAO6zHSVKGNUiL+MEflC4Bm1YqQ+lvf4=";
  };

  # Build dagster-shared (internal utilities)
  dagster-shared = python312Packages.buildPythonPackage {
    pname = "dagster-shared";
    version = "1.9.11";

    src = runCommand "dagster-shared-source" {} ''
      cp -r ${dagster-src}/python_modules/libraries/dagster-shared $out
      chmod -R u+w $out
    '';

    format = "setuptools";

    nativeBuildInputs = with python312Packages; [
      setuptools
      wheel
    ];

    propagatedBuildInputs = with python312Packages; [
      packaging
      pyyaml
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
    version = "1.9.11";

    src = runCommand "dagster-pipes-source" {} ''
      cp -r ${dagster-src}/python_modules/dagster-pipes $out
      chmod -R u+w $out
    '';

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
    version = "1.9.11";

    src = runCommand "dagster-source" {} ''
      cp -r ${dagster-src}/python_modules/dagster $out
      chmod -R u+w $out
    '';

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
      psutil
      docstring-parser
      rich
      filelock
      pydantic
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
    version = "1.9.11";

    src = runCommand "dagster-graphql-source" {} ''
      cp -r ${dagster-src}/python_modules/dagster-graphql $out
      chmod -R u+w $out
    '';

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
  dagster-webserver = python312Packages.buildPythonPackage {
    pname = "dagster-webserver";
    version = "1.9.11";

    src = runCommand "dagster-webserver-source" {} ''
      cp -r ${dagster-src}/python_modules/dagster-webserver $out
      chmod -R u+w $out
    '';

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

in
# Combine all packages into a single closure
buildEnv {
  name = "dagster-complete-1.9.11";

  paths = [
    dagster-shared
    dagster-pipes
    dagster
    dagster-graphql
    dagster-webserver
  ];

  pathsToLink = [
    "/bin"
    "/lib"
  ];

  meta = {
    description = "Complete Dagster platform with all components";
    homepage = "https://dagster.io";
    longDescription = ''
      Complete Dagster build including:
      - dagster-shared (utilities)
      - dagster-pipes (pipeline communication)
      - dagster (core platform)
      - dagster-graphql (GraphQL API)
      - dagster-webserver (web UI)

      Provides all CLIs: dagster, dagster-daemon, dagster-graphql,
      dagster-webserver, dagster-webserver-debug
    '';
  };
}
