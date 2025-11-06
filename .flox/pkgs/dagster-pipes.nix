# Build dagster-pipes (internal package)
{ python312Packages
, dagster-src
, dagster-shared
}:

python312Packages.buildPythonPackage {
  pname = "dagster-pipes";
  version = "1.9.11";  # Update this when tracking new versions

  src = "${dagster-src}/python_modules/dagster-pipes";

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
}
