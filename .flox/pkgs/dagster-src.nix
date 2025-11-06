# Fetch Dagster source from upstream GitHub
# Update the `rev` to track new versions
{ fetchFromGitHub }:

fetchFromGitHub {
  owner = "dagster-io";
  repo = "dagster";
  rev = "master";  # Or specify a commit/tag like "1.8.7"
  # Leave empty hash initially - flox build will tell you the correct one
  hash = "";
}
