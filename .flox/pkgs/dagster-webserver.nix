# Build dagster-webserver package
{ python312Packages
, dagster-src
, dagster
, dagster-graphql
}:

python312Packages.buildPythonPackage {
  pname = "dagster-webserver";
  version = "1.9.11";  # Update this when tracking new versions

  src = "${dagster-src}/python_modules/dagster-webserver";

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
}
