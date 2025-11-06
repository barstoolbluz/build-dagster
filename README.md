# Dagster Build from Upstream with Flox

This repository builds Dagster packages from the upstream GitHub repository using **Flox Nix Expression Builds**. It allows you to track upstream progress and publish updated packages as Dagster evolves.

## Overview

This uses Flox's **§10 Nix Expression Builds** feature to:
- Fetch Dagster source directly from `github:dagster-io/dagster`
- Build all Dagster packages from source
- Publish to Flox Catalog for reuse
- Track upstream updates by changing source reference

## Structure

```
dagster-build/
├── .flox/
│   ├── env/
│   │   └── manifest.toml       # Flox environment definition
│   └── pkgs/                   # Nix expressions for building
│       ├── dagster-src.nix     # Fetches upstream source
│       ├── dagster-shared.nix  # Builds internal package
│       ├── dagster-pipes.nix   # Builds internal package
│       ├── dagster.nix         # Builds main package
│       ├── dagster-graphql.nix # Builds GraphQL package
│       └── dagster-webserver.nix # Builds web server
└── README.md                   # This file
```

## Quick Start

### 1. Build All Packages

```bash
cd dagster-build

# Build all packages (will take several minutes first time)
flox build

# Or build specific package
flox build dagster
flox build dagster-webserver
```

### 2. Install and Use

```bash
# Activate environment with built packages
flox activate

# Check Dagster installation
python -c "import dagster; print(dagster.__version__)"

# Or install in another environment
cd ~/my-project
flox install ../dagster-build/.#dagster
```

### 3. Publish to Catalog

```bash
# First time: authenticate
flox auth login

# Publish all packages to your personal catalog
flox publish

# Or publish to organization catalog
flox publish -o myorg

# Packages will be available as:
# - your-handle/dagster
# - your-handle/dagster-graphql
# - your-handle/dagster-webserver
```

## Tracking Upstream Updates

### Update to Latest Master

1. **Get latest commit hash from GitHub**:
   ```bash
   # Visit https://github.com/dagster-io/dagster/commits/master
   # Copy the latest commit hash (e.g., abc123def456)
   ```

2. **Update source reference**:
   Edit `.flox/pkgs/dagster-src.nix`:
   ```nix
   rev = "abc123def456";  # Update this
   hash = "";             # Clear the hash
   ```

3. **Get new hash**:
   ```bash
   flox build dagster-src
   # Error message will show correct hash
   # Copy it back into dagster-src.nix
   ```

4. **Build and test**:
   ```bash
   flox build
   flox activate
   python -c "import dagster; print(dagster.__version__)"
   ```

5. **Publish updated packages**:
   ```bash
   git add .flox/
   git commit -m "Update Dagster to abc123def456"
   flox publish
   ```

### Pin to Specific Tag

Edit `.flox/pkgs/dagster-src.nix`:
```nix
rev = "1.8.7";  # Or any tag/version
hash = "";      # Will get from build error
```

Then follow steps 3-5 above.

## Version Management

When updating to new versions:

1. **Update version numbers** in all `.flox/pkgs/*.nix` files:
   ```nix
   version = "1.9.11";  # Change to new version
   ```

2. **Update source reference** in `dagster-src.nix`

3. **Rebuild and verify**:
   ```bash
   flox build
   ```

4. **Publish with version tag**:
   ```bash
   git tag v1.9.11
   git push --tags
   flox publish
   ```

## Package Dependencies

The build order is automatically handled by Nix:
1. `dagster-src` - Fetches upstream source
2. `dagster-shared` - Internal utilities
3. `dagster-pipes` - Depends on dagster-shared
4. `dagster` - Main package, depends on pipes and shared
5. `dagster-graphql` - Depends on dagster
6. `dagster-webserver` - Depends on dagster and graphql

## Troubleshooting

### Hash Mismatch Error

```
error: hash mismatch in fixed-output derivation
```

**Solution**: Leave `hash = "";` in the Nix file, run `flox build`, copy the hash from the error message, and update the file.

### Missing Python Dependencies

```
ModuleNotFoundError: No module named 'xyz'
```

**Solution**: Add the missing package to `propagatedBuildInputs` in the appropriate `.flox/pkgs/*.nix` file.

### Build Takes Forever

The first build fetches and compiles everything. Subsequent builds are cached. Use `flox build -v` for verbose output to see progress.

### Cannot Publish

```
error: environment must be in a git repository
```

**Solution**:
```bash
git add .
git commit -m "Add Dagster builds"
git remote add origin <your-repo-url>
git push -u origin master
```

## Maintenance Workflow

### Weekly Update Routine

```bash
# 1. Check for new Dagster releases
#    https://github.com/dagster-io/dagster/releases

# 2. Update source reference
vim .flox/pkgs/dagster-src.nix

# 3. Update version numbers in all package files
vim .flox/pkgs/dagster*.nix

# 4. Build and test
flox build
flox activate -- python -c "import dagster; print(dagster.__version__)"

# 5. Commit and publish
git add .flox/
git commit -m "Update Dagster to <version>"
git push
flox publish
```

### Adding More Dagster Packages

To add packages like `dagster-postgres`, `dagster-docker`, etc.:

1. Create `.flox/pkgs/dagster-postgres.nix`:
   ```nix
   { python312Packages, dagster-src, dagster }:
   python312Packages.buildPythonPackage {
     pname = "dagster-postgres";
     version = "1.9.11";
     src = "${dagster-src}/python_modules/libraries/dagster-postgres";
     propagatedBuildInputs = with python312Packages; [
       dagster
       psycopg2
     ];
     doCheck = false;
   }
   ```

2. Build and publish:
   ```bash
   git add .flox/pkgs/dagster-postgres.nix
   flox build dagster-postgres
   flox publish
   ```

## Using Published Packages

After publishing, anyone can use your packages:

```bash
# In any Flox environment
flox install your-handle/dagster
flox install your-handle/dagster-webserver

# Or in manifest.toml
[install]
dagster.pkg-path = "your-handle/dagster"
dagster-webserver.pkg-path = "your-handle/dagster-webserver"
```

## Benefits of This Approach

✅ **No Fork Required** - Fetches directly from upstream
✅ **Version Control** - Track exactly which commit you're building
✅ **Reproducible** - Same inputs = same outputs
✅ **Shareable** - Publish for team or personal use
✅ **Maintainable** - Update source reference and rebuild
✅ **Composable** - Mix with other Flox environments

## Advanced: Customizing Builds

### Override Dependencies

Create a modified version:

```nix
# .flox/pkgs/dagster-custom.nix
{ python312Packages, dagster-src, dagster-shared, dagster-pipes }:
(python312Packages.buildPythonPackage {
  # ... same as dagster.nix ...
}).overrideAttrs (oldAttrs: {
  # Custom modifications
  propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [
    python312Packages.my-custom-package
  ];
})
```

### Apply Patches

```nix
{ python312Packages, dagster-src, dagster-shared, dagster-pipes }:
python312Packages.buildPythonPackage {
  # ... normal definition ...
  patches = [ ./my-dagster.patch ];
}
```

## Resources

- [Dagster Documentation](https://docs.dagster.io/)
- [Dagster GitHub](https://github.com/dagster-io/dagster)
- [Flox Documentation](https://flox.dev/docs)
- [Flox Build System](https://flox.dev/docs/tutorials/building-packages/)
- [Nix Package Building](https://nixos.org/manual/nixpkgs/stable/#chap-pkgs-python)

## License

This build configuration is MIT. Dagster itself is Apache License 2.0.
