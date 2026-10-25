# bash-hooks

`bash-hooks` manages project hooks and provides reusable scripts for checks, formatting, testing, builds, and other development tasks.

## Table of Contents

- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Global Installation](#global-installation)
- [CLI Reference](#cli-reference)
- [Package Reference](#package-reference)
  - [Golang](#golang)
  - [Node.js](#nodejs)
  - [Elixir/Mix](#elixirmix)
  - [Zig](#zig)
  - [Shell](#shell)
  - [Tools](#tools)
- [Dependencies](#dependencies)

## Getting Started

1. Install `bash-hooks` using the [global installer](#global-installation), or use the script directly in your workspace.
2. Create a `pre-commit-build.yaml` configuration file in the workspace root.
3. Configure the local and remote scripts to run.
4. Run `bash-hooks` to generate or update the hook script.

## Configuration

By default, the configuration file must be named `pre-commit-build.yaml` and placed in the workspace root.

Start from the [configuration template](https://github.com/Rafael24595/bash-hooks/blob/main/pre-commit-build.template.yaml).

### Structure

- `hooks` (**required**)
  - `remote.repos`: list of remote script repositories.
  - `local.scripts`: list of local scripts.

### Common script fields

These fields are used by remote and local script entries:

| Field | Description |
| --- | --- |
| `id` | Script identifier. |
| `disabled` | Whether the script is disabled. |
| `expect` | Expected execution result: `true` for exit code `0`, `false` for a non-zero exit code. |
| `return` | Configured return behavior: `true` for `1`, `false` for `0`. |
| `flags` | Flags passed to the script, specified without the `--` prefix. |
| `args` | Arguments passed to the script. |

### Remote script fields

| Field | Description |
| --- | --- |
| `origin` | URL of the Git repository. |
| `tag` | Repository tag to use. |
| `target` | Path containing the script. |
| `name` | Script name. |

### Local script fields

| Field | Description |
| --- | --- |
| `path` | Path to the local script. |

See the [configuration template](https://github.com/Rafael24595/bash-hooks/blob/main/pre-commit-build.template.yaml) for a complete example.

## Global Installation

The global installer (`install.sh`) installs `bash-hooks` in the user's local binary directory and adds its directory to `PATH`.

Default installation path:

```text
~/.local/bin/bash-hooks/bash-hooks
```

The installer configures the following directory in `~/.bashrc`:

```text
~/.local/bin/bash-hooks
```

After installation, the `bash-hooks` command can be run from any workspace. Reload the shell configuration or open a new terminal:

```bash
source ~/.bashrc
```

### Installer commands

| Option | Description |
| --- | --- |
| `-h`, `--help` | Displays installer help. |
| `-v`, `--version` | Shows the installer version. |
| `-i`, `--install` | Installs `bash-hooks`. Installation is the default action when no argument is supplied. |
| `-r[=<tag>]`, `--remote[=<tag>]` | Downloads and installs `bash-hooks` from GitHub to the specified tag, or to the latest version if no tag is provided. |
| `-u`, `--uninstall` | Removes the global installation and its `PATH` configuration from `~/.bashrc`. |

The `--remote` option supports `bash-hooks` versions `0.16.0` and later. Earlier versions used the name `install-pre-commit` and are not supported by this remote installer.

Without a tag, remote installation downloads the latest version available from the main branch.

## CLI Reference

By default, the `bash-hooks`script is located in the same workspace as the installer, but it can also be installed globally.

### Commands and options

| Option | Description |
| --- | --- |
| `-h`, `--help` | Displays help. |
| `-u`, `--update[=<tag>]` | Updates the script to the specified tag, or to the latest version if no tag is provided. |
| `-v`, `--version` | Displays the current version. |
| `-t` | Runs the script in test mode, placing it in the remote-scripts directory so Git will not use it as a hook. |
| `-e`, `--enable[=<id>[,<id>...]]` | Enables the hook, or enables only the specified script IDs. |
| `-d`, `--disable[=<id>[,<id>...]]` | Disables the hook, or disables only the specified script IDs. |
| `--workspace=<path>` | Sets the workspace where the script will be placed. |
| `--input=<path>` | Sets the input configuration file path. |
| `--output=<path>` | Sets the generated script path. |
| `-b`, `--block` | Generates a single-file script without imports. |
| `--mode=<mode>` | Sets the build mode. Supported values: `pre_commit` and `pre_push`. |
| `--pull=<script>:<tag>` | Downloads a remote script at the specified version. |

Examples:

```bash
# Enable selected scripts
./bash-hooks --enable=check-staged,run-linter

# Disable a selected script
./bash-hooks --disable=run-linter

# Select a workspace and configuration file
./bash-hooks --workspace=../other_project/my_project
./bash-hooks --input=.test.yaml
./bash-hooks --output=.test.sh

# Generate a single-file script
./bash-hooks --block

# Select the hook mode
./bash-hooks --mode=pre_commit

# Download a specific remote script version
./bash-hooks --pull=golang/sh/run-govulncheck.sh:0.6.3
```

## Package Reference

### Golang

#### `check-go-context.sh`

Executes checks to validate whether the current project is a valid Go project.

**Flags**

| Flag | Description |
|---|---|
| `--project`, `--p` | Verifies if this is a Go project. |
| `--staged`, `--s` | Checks for staged Go files. |
| `--install`, `--i` | Verifies if Go is installed. |

If no flags are selected, all checks are executed.

#### `run-fieldalignment.sh`

Runs the `fieldalignment` tool to analyze Go struct memory layout and detect potential memory savings.

**Flags**

| Flag | Description |
|---|---|
| `--percent`, `--p` | Defines the minimum percentage of memory savings required for the check to fail. Default: `25%`. |

#### `run-formatter.sh`

Formats all Go files.

#### `run-linter.sh`

Runs `golangci-lint` to identify errors in staged Go files.

**Flags**

| Flag | Description |
|---|---|
| `--install`, `--i` | Installs the latest version of `golangci-lint` if it is not already installed. |
| `--strict`, `--s` | Enables strict mode. If any file contains errors, regardless of whether it is staged, the execution is marked as failed. |
| `--enable=<lnt>`, `--e=<lnt>` | Enables a specific linter. Can be specified multiple times. Linters are combined into a comma-separated list. |

**Dependencies**

- `golangci-lint` — `1.62.0` ([GitHub](https://github.com/golangci/golangci-lint))

#### `run-tests.sh`

Runs all Go tests.

**Flags**

| Flag | Description |
|---|---|
| `--tags=<tag>`, `--t=<tag>` | Defines the test build tags. Can be specified multiple times. Tags are combined into a comma-separated list. |
| `--race`, `--r` | Runs tests using the race detector. |
| `--cover=<threshold>`, `--c=<threshold>` | Runs tests with coverage analysis. If a threshold is specified, the check fails when coverage falls below that value. The threshold can be expressed as a percentage (e.g., `80.0`) or as an absolute number of statements (e.g., `100`). |

#### `run-govulncheck.sh`

Runs `govulncheck` to check dependencies for known vulnerabilities.

**Flags**

| Flag | Description |
|---|---|
| `--install` | Installs the latest version of `govulncheck` if it is not already installed. |

**Dependencies**

- `govulncheck` — `v1.1.4` ([GitHub](https://github.com/golang/vuln))

#### `run-coverage-black-box.sh`

Runs black-box tests on Go packages and calculates code coverage. By default, it checks whether the test directory structure matches the source structure and verifies that coverage meets or exceeds the specified minimum.

**Flags**

| Flag | Description |
|---|---|
| `--verbose`, `--v` | Displays coverage details. |
| `--success-empty`, `--se` | Treats the absence of tests as a successful result. |
| `--invalid-empty`, `--ie` | Treats packages with no discovered tests as valid. |
| `--package=<pkg>`, `--p=<pkg>` | Manually specifies one or more packages to analyze. Can be repeated to include multiple packages. |

**Arguments**

- Minimum coverage percentage (e.g., `80.0`).

### Node.js

#### `run-npm-run.sh`

Executes an npm script based on a configurable argument.

**Arguments**

- Script name (e.g., `build`, `dev`, `test`).

**Dependencies**

- `node` — Tested with Node.js v18+, but should work with other versions ([Official website](https://nodejs.org/en)).

#### `run-eslint.sh`

Runs ESLint to analyze code consistency and identify errors.

**Flags**

| Flag | Description |
|---|---|
| `--force-all`, `--fa` | Runs ESLint on all configured project files. If omitted, only staged files are analyzed. |

**Dependencies**

- `node` — Tested with Node.js v18+, but should work with other versions ([Official website](https://nodejs.org/en)).
- `eslint` — `9.34.0` ([npm](https://www.npmjs.com/package/eslint)).
- `eslint-formatter-unix` — `8.40.0` ([npm](https://www.npmjs.com/package/eslint-formatter-unix)).

### Elixir/Mix

#### `check-mix-context.sh`

Executes checks to validate whether the current project is a valid Mix project.

**Flags**

| Flag | Description |
|---|---|
| `--project`, `--p` | Verifies if this is a Mix project. |
| `--staged`, `--s` | Checks for staged Elixir files (`*.ex` / `*.exs`). |
| `--install`, `--i` | Verifies if Elixir and Mix are installed. |

If no flags are selected, all checks are executed.

#### `run-mix-tests.sh`

Runs all Mix tests.

**Dependencies**

- `Mix` — `^1.12.0` ([Mix.Task.Test documentation](https://hexdocs.pm/mix/Mix.Tasks.Test.html)).

#### `run-credo.sh`

Runs Credo to analyze code consistency and identify potential issues.

**Flags**

| Flag | Description |
|---|---|
| `--static`, `--s` | Includes all issues in the report. If omitted, only positive-priority issues (↑ ↗ →) are reported. |
| `--force-all`, `--fa` | Runs Credo on all project files. If omitted, only staged files are analyzed. |

**Dependencies**

- `Credo` — `v1.7.12` ([Documentation](https://hexdocs.pm/credo/overview.html)).

### Zig

#### `check-zig-context.sh`

Executes checks to validate whether the current project is a valid Zig project.

**Flags**

| Flag | Description |
|---|---|
| `--project`, `--p` | Verifies if this is a Zig project. |
| `--staged`, `--s` | Checks for staged Zig files (`*.zig` / `*.zon`). |
| `--install`, `--i` | Verifies if Zig is installed. |

If no flags are selected, all checks are executed.

#### `run-check.sh`

Runs Zig's `ast-check` on staged Zig files to detect errors.

#### `run-fmt.sh`

Runs Zig's formatter to check staged files for formatting issues and optionally fix them.

**Flags**

| Flag | Description |
|---|---|
| `--apply`, `--a` | Fixes formatting issues and adds the corrected files back to the Git staging area. |

#### `run-tests.sh`

Runs all Zig tests.

### Shell

#### `run-linter.sh`

Runs `bash -n` and `shellcheck` to identify syntax and other potential issues in staged Shell files.

**Dependencies**

- `shellcheck` — `0.8.0` ([Official website](https://www.shellcheck.net)).

### Tools

#### `check-large-files.sh`

Searches for large files based on a configurable file-size threshold, specified in bytes.

## Dependencies

| Dependency | Version / notes |
| --- | --- |
| `yq` | `v4.44.2`. See the [yq repository](https://github.com/mikefarah/yq). Snap installations may not work as expected; see the [snap notes](https://github.com/mikefarah/yq/#snap-notes). |
