# Build main dagster package
{ python312Packages
, dagster-src
, dagster-shared
, dagster-pipes
}:

python312Packages.buildPythonPackage {
  pname = "dagster";
  version = "1.9.11";  # Update this when tracking new versions

  src = "${dagster-src}/python_modules/dagster";

  format = "setuptools";

  nativeBuildInputs = with python312Packages; [
    setuptools
    wheel
  ];

  propagatedBuildInputs = with python312Packages; [
    # Core dependencies from setup.py
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
  ] ++ [
    # Internal packages
    dagster-pipes
    dagster-shared
  ];

  doCheck = false;

  pythonImportsCheck = [ "dagster" ];

  meta = {
    description = "The orchestration platform for the development, production, and observation of data assets";
    homepage = "https://dagster.io";
  };
}
