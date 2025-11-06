# Build dagster-graphql package
{ python312Packages
, dagster-src
, dagster
}:

python312Packages.buildPythonPackage {
  pname = "dagster-graphql";
  version = "1.9.11";  # Update this when tracking new versions

  src = "${dagster-src}/python_modules/dagster-graphql";

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
    starlette
  ];

  doCheck = false;

  pythonImportsCheck = [ "dagster_graphql" ];

  meta = {
    description = "Dagster GraphQL API";
    homepage = "https://dagster.io";
  };
}
