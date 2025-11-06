# Build dagster-shared (internal package)
{ python312Packages
, dagster-src
, runCommand
}:

python312Packages.buildPythonPackage {
  pname = "dagster-shared";
  version = "1.9.11";  # Update this when tracking new versions

  src = runCommand "dagster-shared-source" {} ''
    cp -r ${dagster-src}/python_modules/libraries/dagster-shared $out
    chmod -R u+w $out
  '';

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
