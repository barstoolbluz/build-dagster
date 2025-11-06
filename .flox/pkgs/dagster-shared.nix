# Build dagster-shared (internal package)
{ python312Packages
, dagster-src
}:

python312Packages.buildPythonPackage {
  pname = "dagster-shared";
  version = "1.9.11";  # Update this when tracking new versions

  src = "${dagster-src}/python_modules/dagster-shared";

  format = "setuptools";

  nativeBuildInputs = with python312Packages; [
    setuptools
    wheel
  ];

  doCheck = false;

  pythonImportsCheck = [ "dagster_shared" ];

  meta = {
    description = "Dagster shared utilities";
    homepage = "https://dagster.io";
  };
}
