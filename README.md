# Dagster Build from Upstream with Flox

This repository builds Dagster packages from the upstream GitHub repository using **Flox Nix Expression Builds**. It allows you to track upstream progress and publish updated packages as Dagster evolves.

## Overview

This provides **two ways** to build and use Dagster:

### Option 1: Nix Flake (for Nix users)
- Use `nix build`, `nix run`, `nix develop` directly
- No Flox required
- Standard Nix flake interface
- Perfect for integrating into existing Nix workflows

### Option 2: Flox Environment (for Flox users)
- Use Flox's **§10 Nix Expression Builds** feature
- Build, publish, and share via Flox Catalog
- Track upstream updates by changing source reference
- Composable with other Flox environments

## Structure

```
dagster-build/
├── flake.nix                   # Nix flake interface
├── flake.lock                  # Locked flake inputs
├── default.nix                 # Backward compatibility for non-flake users
├── BUILD_VERSIONS.md           # Guide for building different versions
├── .flox/
│   ├── env/
│   │   └── manifest.toml       # Flox environment definition
│   └── pkgs/
│       └── dagster.nix         # Single Nix expression building all components
└── README.md                   # This file
```

**Note**: We use a **single Nix expression** (`dagster.nix`) that builds all Dagster components in one closure. This is simpler to maintain and update than separate files per component.

## Quick Start

### Option A: Using the Nix Flake

For Nix users without Flox:

#### 1. Build the Package

```bash
cd dagster-build

# Build Dagster (uses Nix cache if available)
nix build .#dagster

# Or use without experimental features flag (if flakes enabled globally)
nix build
```

#### 2. Run Dagster CLIs Directly

```bash
# Run main dagster CLI
nix run .#dagster -- --version

# Run dagster webserver
nix run .#dagster-webserver -- --help

# Run dagster daemon
nix run .#dagster-daemon -- --help

# Run dagster-graphql
nix run .#dagster-graphql -- --help
```

#### 3. Enter Development Shell

```bash
# Enter shell with Dagster available
nix develop

# Now you can use all Dagster commands
dagster --version
dagster-webserver --version
python -c "import dagster; print(dagster.__version__)"
```

#### 4. Use in Your Own Flake

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    dagster.url = "github:yourname/dagster-build";  # Update with your repo
  };

  outputs = { self, nixpkgs, dagster }:
    let
      system = "x86_64-linux";  # or your system
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          dagster.packages.${system}.dagster
        ];
      };
    };
}
```

#### 5. Non-Flake Usage

For users without flakes enabled:

```bash
# Build with legacy nix-build
nix-build

# Result symlink points to Dagster
./result/bin/dagster --version
```

### Option B: Using Flox

For Flox users:

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

## Updating to Different Versions

**See [BUILD_VERSIONS.md](BUILD_VERSIONS.md) for comprehensive guide on building different Dagster versions.**

### Quick Version Update

The easiest way to build a different version:

1. **Edit `.flox/pkgs/dagster.nix`** - Change version in 8 places:
   - Line 15: `rev = "X.Y.Z"`
   - Lines 16, 22, 55, 81, 141, 175, 179, 210, 249, 250: `version = "X.Y.Z"`
   - Clear both hashes to `""`

2. **Get correct hashes**:
   ```bash
   # For Nix users:
   nix build .#dagster  # Error shows GitHub hash
   # Update hash, build again for PyPI hash

   # For Flox users:
   flox build  # Error shows GitHub hash
   # Update hash, build again for PyPI hash
   ```

3. **Test the build**:
   ```bash
   # Nix:
   nix run .#dagster -- --version

   # Flox:
   flox activate -- dagster --version
   ```

### Available Binaries

All versions provide these 8 binaries:
- `dagster` - Main CLI
- `dagster-daemon` - Background daemon
- `dagster-webserver` - Web UI server
- `dagster-webserver-debug` - Debug webserver
- `dagster-graphql` - GraphQL API server
- `dagster-init-config` - Configuration generator
- `dagster-welcome` - Environment welcome message
- `dagster-info` - Environment information

## How It Works

**Single Nix Expression Pattern:**

This build uses a **single Nix expression** (`.flox/pkgs/dagster.nix`) that builds all Dagster components in one unified closure:

1. **Fetches upstream source** from GitHub (dagster-io/dagster)
2. **Builds internal packages** (dagster-shared, dagster-pipes) from source
3. **Builds main components** (dagster, dagster-graphql, dagster-webserver, dagster-postgres)
4. **Combines everything** using `symlinkJoin` into a single output with all binaries

**Key advantage:** Update the version once in `dagster.nix`, and all components stay synchronized.

**Flake wrapper:** The `flake.nix` imports this Nix expression and exposes it via standard Nix flake outputs. The flake doesn't need to change when updating versions - only `dagster.nix` does.

## Package Components

Built in a single closure with automatic dependency management:
- **dagster-shared** - Internal utilities (from GitHub)
- **dagster-pipes** - Pipeline communication (from GitHub)
- **dagster** - Main orchestration platform (from GitHub)
- **dagster-graphql** - GraphQL API (from GitHub)
- **dagster-webserver** - Web UI with pre-built assets (from PyPI)
- **dagster-postgres** - PostgreSQL integration (from GitHub)

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

**Solution**: Add the missing package to `propagatedBuildInputs` in `.flox/pkgs/dagster.nix` for the affected component.

### Build Takes Forever

The first build fetches and compiles everything. Subsequent builds are cached.

**For Nix users:** Use `nix build -L` for live build logs
**For Flox users:** Use `flox build -v` for verbose output

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

### Updating to a New Dagster Version

See [BUILD_VERSIONS.md](BUILD_VERSIONS.md) for detailed instructions. Quick summary:

```bash
# 1. Check for new Dagster releases
#    https://github.com/dagster-io/dagster/releases

# 2. Edit .flox/pkgs/dagster.nix
#    Update version in 8 locations (rev + all version fields)
#    Clear both hashes to ""

# 3. Get GitHub source hash
nix build .#dagster  # or: flox build
# Copy hash from error, update dagster.nix

# 4. Get PyPI webserver hash
nix build .#dagster  # or: flox build
# Copy hash from error, update dagster.nix

# 5. Build and test
nix build .#dagster  # or: flox build
nix run .#dagster -- --version  # or: flox activate -- dagster --version

# 6. Commit and publish
git add .flox/pkgs/dagster.nix
git commit -m "Update Dagster to X.Y.Z"
git push

# For Flox users:
flox publish
```

### Adding More Dagster Components

The current build already includes PostgreSQL support (`dagster-postgres`). To add more components like `dagster-docker`, `dagster-aws`, etc., add them to the single `.flox/pkgs/dagster.nix` file:

1. Add the new component's build definition inside `dagster.nix` (follow the pattern of existing components)
2. Add it to `dagsterPythonEnv` packages list
3. Rebuild with `nix build` or `flox build`

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

Since we use a single Nix expression, customizations are made directly in `.flox/pkgs/dagster.nix`.

### Adding Custom Dependencies

Edit the appropriate component's `propagatedBuildInputs` in `dagster.nix`:

```nix
# Example: Add custom package to main dagster component
dagster = python312Packages.buildPythonPackage {
  # ... existing config ...
  propagatedBuildInputs = with python312Packages; [
    # ... existing dependencies ...
    my-custom-package  # Add your package here
  ];
};
```

### Applying Patches

Add patches to specific components:

```nix
# In dagster.nix, for the component you want to patch
dagster = python312Packages.buildPythonPackage {
  # ... existing config ...
  patches = [ ./my-dagster.patch ];
};
```

### Overriding Python Version

Change the Python version throughout the build by modifying the top of `dagster.nix`:

```nix
# Replace python312 with python311 or python313
{ python311        # Change this
, python311Packages  # And this
, fetchFromGitHub
, fetchPypi
, symlinkJoin
, makeWrapper
}:
```

## Resources

- [Dagster Documentation](https://docs.dagster.io/)
- [Dagster GitHub](https://github.com/dagster-io/dagster)
- [Flox Documentation](https://flox.dev/docs)
- [Flox Build System](https://flox.dev/docs/tutorials/building-packages/)
- [Nix Package Building](https://nixos.org/manual/nixpkgs/stable/#chap-pkgs-python)

## License

This build configuration is MIT. Dagster itself is Apache License 2.0.
