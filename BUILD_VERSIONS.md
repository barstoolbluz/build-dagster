# Building Different Dagster Versions

This build environment uses a **single Nix expression** that can be edited to build any version of Dagster.

## Current Version

**Currently configured:** Dagster 1.12.1

## How to Build a Different Version

### Step 1: Edit the Nix Expression

Open `.flox/pkgs/dagster.nix` and update the version in **TWO places**:

#### A. Update the source fetch (lines 11-16):

```nix
dagster-src = fetchFromGitHub {
  owner = "dagster-io";
  repo = "dagster";
  rev = "X.Y.Z";    # Change to your target version
  hash = "";         # Leave empty initially
};
```

#### B. Update all package versions (search for `version =`):

There are **7 occurrences** to update:
1. `dagster-shared` (line ~22)
2. `dagster-pipes` (line ~55)
3. `dagster` (line ~81)
4. `dagster-graphql` (line ~141)
5. `dagster-webserver` (line ~175 AND ~179 - two places!)
6. `dagster-postgres` (line ~210)
7. `symlinkJoin name` (line ~249)
8. `symlinkJoin version` (line ~250)

**Example: To build version 1.13.0:**

```nix
# In fetchFromGitHub:
rev = "1.13.0";

# All buildPythonPackage blocks:
version = "1.13.0";

# In symlinkJoin:
name = "dagster-1.13.0";
version = "1.13.0";
```

### Step 2: Get the Correct Hash

#### For GitHub source (dagster-src):

1. Leave `hash = "";` (empty string)
2. Run `flox build`
3. The build will fail with error showing the correct hash
4. Copy the hash from the error message
5. Update `dagster-src` with the correct hash
6. Run `flox build` again

#### For PyPI source (dagster-webserver):

1. Leave `hash = "";` (empty string)
2. Run `flox build`
3. The build will fail with error showing the correct hash
4. Copy the hash from the error message
5. Update `dagster-webserver` fetchPypi with the correct hash
6. Run `flox build` again

### Step 3: Build

```bash
cd /home/daedalus/dev/testes/dagster-build
flox build
```

### Step 4: Test (Optional)

```bash
# Test the built package
./result/bin/dagster --version

# Test helper scripts
./result/bin/dagster-welcome
./result/bin/dagster-info
```

### Step 5: Publish

```bash
# Commit changes
git add .flox/pkgs/dagster.nix
git commit -m "Update Dagster to version X.Y.Z"
git push

# Publish to Flox catalog
flox publish dagster
```

## Quick Reference: Finding Dagster Versions

### Latest stable release:
```bash
curl -s https://api.github.com/repos/dagster-io/dagster/releases/latest | grep '"tag_name"'
```

### Recent releases:
```bash
curl -s https://api.github.com/repos/dagster-io/dagster/releases | grep '"tag_name"' | head -10
```

### Check PyPI versions:
```bash
# Visit: https://pypi.org/project/dagster-webserver/#history
```

## Version Compatibility Notes

- **dagster-webserver** must be fetched from PyPI (not GitHub) because it includes pre-built webapp UI assets
- All other packages are built from the same GitHub source
- Python 3.12 is used for all builds (configured in the Nix expression)
- PostgreSQL support requires `dagster-postgres` package (already included)

## Troubleshooting

### Hash mismatch error:
- This is **expected** on first build after changing version
- Copy the correct hash from the error message
- Update the Nix expression with the correct hash

### Build fails with missing dependencies:
- Check if the new version requires additional Python packages
- Add them to the appropriate `propagatedBuildInputs` list

### PyPI package not found:
- Verify the version exists on PyPI: https://pypi.org/project/dagster-webserver/#history
- Some versions may only be on GitHub (use fetchFromGitHub for all packages)

## Example: Complete Version Update

```bash
# 1. Edit .flox/pkgs/dagster.nix
#    - Change rev to "1.13.0"
#    - Change all version = "1.12.1" to version = "1.13.0"
#    - Set both hashes to ""

# 2. Get GitHub hash
flox build
# Copy hash from error, update dagster-src

# 3. Get PyPI hash
flox build
# Copy hash from error, update dagster-webserver

# 4. Build
flox build

# 5. Test
./result/bin/dagster --version

# 6. Publish
git add .flox/pkgs/dagster.nix
git commit -m "Update Dagster to 1.13.0"
git push
flox publish dagster
```

## Notes

- The package name remains `dagster` regardless of version
- Publishing a new version **replaces** the previous version in your catalog
- Users install with: `flox install your-catalog/dagster`
- To maintain multiple versions simultaneously, create separate .nix files (e.g., `dagster-1-12-0.nix`, `dagster-1-13-0.nix`)
