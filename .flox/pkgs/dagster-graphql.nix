# Build dagster-graphql package
{ python312Packages
, dagster-src
, dagster
, runCommand
}:

python312Packages.buildPythonPackage {
  pname = "dagster-graphql";
  version = "1.12.0";

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
}
