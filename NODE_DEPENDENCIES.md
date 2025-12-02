# Node Dependency Handling in mediawiki-quickstart

This document explains how mediawiki-quickstart manages Node.js dependencies for MediaWiki core and its components (skins and extensions)

## The Problem

MediaWiki's ecosystem consists of a core application plus many skins and extensions, each potentially having their own `package.json` with Node dependencies. A naive approach—running `npm install` separately in each component directory—would be:

- **Slow**: Dependency resolution happens independently for each component
- **Disk-heavy**: Packages are duplicated across many separate `node_modules` directories

## The Solution: NPM Workspaces

Quickstart leverages [npm workspaces](https://docs.npmjs.com/cli/v7/using-npm/workspaces) to hoist all skin and extension dependencies up to MediaWiki core's root `node_modules`. A single `npm install` at the root satisfies dependencies for core and all installed components

### How It Works

Node dependency installation is triggered in two scenarios:

**During `./fresh_install`** (installs MediaWiki core):
1. MediaWiki core is cloned
2. The Vector skin is installed via the component installer
3. Node dependencies are resolved for core + Vector

**During `./install`** (installs skins/extensions):
1. Requested components are cloned into the existing `mediawiki/extensions/` or `mediawiki/skins/` directories
2. Node dependencies are re-resolved to include the new components

In both cases, the installer:

1. Runs `configure_npm_workspaces` to modify MediaWiki core's `package.json`
2. Runs `npm install` once from the MediaWiki root directory

The `configure_npm_workspaces` script adds workspace configuration to core's `package.json`:

```json
{
  "private": true,
  "workspaces": [".", "extensions/*", "skins/*"]
}
```

This tells npm to treat all directories matching `extensions/*` and `skins/*` as workspace members, hoisting their dependencies to the root `node_modules` where possible

## Benefits

| Approach | Install Time | Disk Usage | Deduplication |
|----------|--------------|------------|---------------|
| Per-component `npm install` | Slow | High | None |
| Workspaces (Quickstart) | Fast | Low | Automatic |

Workspaces provide:

- **Single dependency resolution pass** for all components
- **Automatic deduplication** of shared packages
- **Unified `node_modules`** at the MediaWiki root
- **Simplified component authoring** (no npm commands needed in setup scripts)

These benefits are especially pronounced when using `./install` to install a large number of extensions and skins at once. Without workspace hoisting, each component would require its own dependency resolution pass and maintain its own `node_modules` directory—resulting in significant time and disk space overhead that scales with the number of components

## For Component Authors

When creating a component manifest for Quickstart:

> **Do not** use `npm install`, `npm ci`, or any other npm commands in your component's `setup.sh` file

The installer automatically detects and handles Node dependencies when your component contains:
- `package.json`
- `package-lock.json`

Your component's dependencies will be installed as part of the unified workspace install

### Example Component Structure

```
extensions/
  └── YourExtension/
      ├── LocalSettings.php    (required)
      ├── setup.sh             (optional - but NO npm commands here)
      └── dependencies.yml     (optional)
```

## Implementation Details

### Scripts

Two scripts handle Node dependency management:

**`installer/configure_npm_workspaces`** (Node.js)
- Reads MediaWiki core's `package.json`
- Backs up the original to `package.json.orig`
- Adds `private: true` (required for workspaces)
- Adds workspace globs for extensions and skins *only if not already present*
- Writes the modified `package.json`

This script is idempotent—running it multiple times won't duplicate the workspace configuration

**`installer/install_node_dependencies`** (Bash)
- Calls `configure_npm_workspaces`
- Runs `npm install --legacy-peer-deps --foreground-scripts`

### Shared npm Cache

Quickstart configures a Docker volume for the npm cache, shared across all containers:

```yaml
volumes:
  npm_cache:

services:
  mediawiki:
    environment:
      NPM_CONFIG_CACHE: /var/local/npm
    volumes:
      - npm_cache:/var/local/npm
```

This cache persists across container restarts and fresh installs, significantly speeding up subsequent installations

### Containers with npm Access

The npm cache volume is mounted in these containers:
- `mediawiki` (main container for installation/maintenance)
- `mediawiki-web` (serves the application)
- `mediawiki-jobrunner` (background jobs)
- `selenium` (test execution)

## Troubleshooting

### Dependencies not being installed

Ensure your component's `package.json` is valid JSON. The workspace configuration relies on npm being able to parse all workspace member package files

### Peer dependency warnings

Quickstart uses `--legacy-peer-deps` to handle peer dependency conflicts more permissively, preventing installation failures from strict peer dependency resolution

### Checking installed dependencies

Shell into the mediawiki container and inspect the root `node_modules`:

```bash
./shellto m ls node_modules
```

Or check a specific package:

```bash
./shellto m npm ls <package-name>
```

## Further Reading

- [npm Workspaces Documentation](https://docs.npmjs.com/cli/v7/using-npm/workspaces)
- [MediaWiki Extension Development](https://www.mediawiki.org/wiki/Manual:Developing_extensions)
