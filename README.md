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
2. Create a `pre-commit-build.yaml` or `pre-commit-build.yml` configuration file in the workspace root.
3. Configure the local and remote scripts to run.
4. Run `bash-hooks` to generate or update the hook script.

## Configuration

By default, the configuration file is named `pre-commit-build.yaml` or `pre-commit-build.yml` and must be placed in the workspace root. If both files exist, an error is raised. Use `--input=<path>` to specify a different configuration file.

Start from the [configuration template](https://github.com/Rafael24595/bash-hooks/blob/main/pre-commit-build.template.yml).

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

See the [configuration template](https://github.com/Rafael24595/bash-hooks/blob/main/pre-commit-build.template.yml) for a complete example.

### Script exit codes

Scripts can use the following exit codes to control hook execution:

| Exit code | Behavior |
| --- | --- |
| `0` | Indicates successful execution. The configured `expect` and `return` fields determine the hook result. |
| `1` | Indicates execution failure. The configured `expect` and `return` fields determine the hook result. |
| `2` | Indicates an invalid argument or unsupported option. The hook immediately fails, regardless of the configured `expect` and `return` values. |

Exit code `2` is reserved by `bash-hooks` for argument validation errors and should be used by scripts when receiving unknown or invalid options.

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
./bash-hooks --input=.test.yml
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

#### Go modules

By default, the Go scripts work on the module at the repository root (`go.mod` in the workspace root). Scripts that support it can work on other modules, or on several:

| Flag | Description |
|---|---|
| `--module=<path>`, `--m=<path>` | Works on the module in `<path>`, relative to the repository root. Can be specified multiple times, or as a comma-separated list. `.` is the root module. |
| `--discover`, `--d` | Works on every module of the repository: every tracked or staged `go.mod`, except those under `testdata`, `vendor`, or directories starting with `_` or `.`, which `go ./...` skips too. Cannot be combined with `--module`. |

Paths must stay inside the repository and use `/`: absolute paths, `..` and `\` are rejected with exit code `2`. With `--discover`, a repository without any `go.mod` exits with code `1`.

A staged file belongs to its nearest module: in a repository with modules at `.` and `tools/a`, a change in `tools/a/main.go` belongs to `tools/a`, not to the root.

#### `check-go-context.sh`

Executes checks to validate whether the current project is a valid Go project.

**Flags**

| Flag | Description |
|---|---|
| `--project`, `--p` | Verifies that every module has a `go.mod`. |
| `--staged`, `--s` | Checks that the staged changes touch at least one of the modules: Go files, `go.mod` or `go.sum`, deletions included. |
| `--install`, `--i` | Verifies if Go is installed. |
| `--module=<path>`, `--m=<path>` | Checks the given modules. See [Go modules](#go-modules). |
| `--discover`, `--d` | Checks every module of the repository. See [Go modules](#go-modules). |

If none of `--project`, `--staged` or `--install` is selected, all checks are executed. `--module` and `--discover` only choose which modules are checked.

#### `run-fieldalignment.sh`

Runs `fieldalignment` on each selected Go module and fails if a staged struct wastes too much memory because of the order of its fields.

**Flags**

| Flag | Description |
|---|---|
| `--verbose`, `--v` | Shows the full output of `fieldalignment` for each module. By default only the summary is shown. |
| `--percent=<n>`, `--p=<n>` | Defines the waste, as a percentage of the memory allocated for the struct, from which a struct fails the check. Accepts integers between `0` and `100`. Default: `25`. |
| `--module=<path>`, `--m=<path>` | Checks the given modules. See [Go modules](#go-modules). |
| `--discover`, `--d` | Checks every module of the repository. See [Go modules](#go-modules). |

**Modules and summary**

`fieldalignment` runs on the whole module, from the module's directory, even when a previous one fails. If no file is staged, the script exits without running it. Only the findings in staged files are checked:

- **Size findings** fail when their waste reaches `--percent`. The waste is the one computed by `fieldalignment`, which accounts for the allocator size classes: a struct that could be smaller but would still be allocated the same memory wastes nothing and never fails.
- **Pointer findings** (`leading bytes of pointer data`) only reduce the work of the garbage collector; they are counted but do not fail the check.

After the last module, a summary lists every module with:

- **Structs**: the staged structs whose waste reaches `--percent`.
- **Below**: the staged structs with some waste under `--percent`, or none once allocated.
- **Pointers**: the staged structs with a pointer finding.
- **Unstaged**: the findings in files that are not staged, which are not checked.
- **Result**: passed, structs over the threshold, or `fieldalignment` failed (an exit code other than `0` or `3`, such as a package that does not build), followed by the findings and the last lines of the output of those that failed.

The script exits with code `1` when any module failed.

**Dependencies**

- `fieldalignment` ([golang.org/x/tools](https://pkg.go.dev/golang.org/x/tools/go/analysis/passes/fieldalignment))

#### `run-formatter.sh`

Formats all Go files.

#### `run-linter.sh`

Runs `golangci-lint` in every selected module and reports the issues of the staged Go files.

**Flags**

| Flag | Description |
|---|---|
| `--verbose`, `--v` | Shows the full output of `golangci-lint` for each module. By default only the summary is shown. |
| `--install`, `--i` | Installs the latest version of `golangci-lint` if it is not already installed. |
| `--strict`, `--s` | Enables strict mode: any issue fails the check, whether its file is staged or not. |
| `--enable=<lnt>`, `--e=<lnt>` | Enables a specific linter. Can be specified multiple times. Linters are combined into a comma-separated list. |
| `--module=<path>`, `--m=<path>` | Lints the given modules. See [Go modules](#go-modules). |
| `--discover`, `--d` | Lints every module of the repository. See [Go modules](#go-modules). |

**Staged files and summary**

`golangci-lint` runs on the whole module, from the module's directory; its output is shown only with `--verbose`. Only the issues of staged files fail the check, unless `--strict` is set; the paths are reported relative to the repository root, as Git writes them.

After the last module, a summary lists every module with:

- **Issues**: the issues that decide the result (in staged files, or all of them with `--strict`).
- **Files**: how many files those issues are in.
- **Unstaged**: the issues in files that are not staged, which do not fail the check (`-` with `--strict`).
- **Result**: passed, files with issues, or `golangci-lint` failed (an exit code other than `0` or `1`, such as an invalid configuration), followed by the issues and the last lines of the output of those that failed.

The script exits with code `1` when any module failed.

**Dependencies**

- `golangci-lint` — `1.62.0` ([GitHub](https://github.com/golangci/golangci-lint)); `--path-prefix` is required.

#### `run-tests.sh`

Runs Go tests across the main build configuration and any additional build variants. Each variant is executed as an independent test flow using Go build tags, in every selected module.

**Flags**

| Flag | Description |
|---|---|
| `--verbose`, `--v` | Shows the output of `go test` for every run. By default it is shown only for the runs that fail. This is unrelated to `go test -v`, which the script always uses to count the tests. |
| `--tags=<tag>`, `--t=<tag>` | Defines the build tags for the main test flow. Can be specified multiple times. Tags are combined into a comma-separated list. |
| `--variant-tags=<tag>`, `--vt=<tag>` | Defines an additional build variant. Each occurrence creates an independent test flow using the specified build tags. Can be specified multiple times. |
| `--race`, `--r` | Runs tests using the Go race detector. |
| `--cover`, `--c` | Enables code coverage reporting. |
| `--cover=<threshold>`, `--c=<threshold>` | Enables code coverage reporting and defines the minimum required coverage percentage. The check fails if coverage falls below the specified threshold. Accepts values between `0` and `100`. |
| `--module=<path>`, `--m=<path>` | Runs the tests of the given modules. See [Go modules](#go-modules). |
| `--discover`, `--d` | Runs the tests of every module of the repository. See [Go modules](#go-modules). |

**Build variants**

The main flow uses the tags specified through `--tags`. Each `--variant-tags` occurrence creates an additional independent flow.

Variant tags replace the main flow tags rather than being combined with them. All flows inherit the common execution options, such as race detection and coverage reporting.

**Modules and summary**

Every flow runs in every module, from the module's directory: with two modules and three flows, the tests run six times. All runs are executed even when one fails, and coverage and its threshold apply to each run on its own. The output of `go test` is shown for the runs that fail, or for all of them with `--verbose`.

After the last run, a summary lists every run with its tests, coverage and result, followed by the details of those that failed:

- **tests failed**: the failed tests and packages.
- **did not build or run**: no test failed, but `go test` did; the last lines of its output, which usually hold the build error.
- **coverage below the threshold**: the tests passed, but the coverage did not reach `--cover=<threshold>`.

The script exits with code `1` when any run failed.

**Example**

```bash
# Run the main configuration and two additional build variants
./run-tests.sh \
    --tags=integration,debug \
    --variant-tags=postgres \
    --variant-tags=mysql \
    --race \
    --cover=80
```

This configuration executes three independent test flows:

1. Main flow: `integration,debug`
2. PostgreSQL variant: `postgres`
3. MySQL variant: `mysql`

Each flow runs with race detection and coverage reporting enabled, requiring at least 80% code coverage.

#### `run-govulncheck.sh`

Runs `govulncheck` on each selected Go module to check its dependencies for known vulnerabilities.

**Flags**

| Flag | Description |
|---|---|
| `--verbose`, `--v` | Shows the full output of `govulncheck` for each module. By default only the summary is shown. |
| `--install`, `--i` | Installs the latest version of `govulncheck` if it is not already installed. |
| `--module=<path>`, `--m=<path>` | Scans the given modules. See [Go modules](#go-modules). |
| `--discover`, `--d` | Scans every module of the repository. See [Go modules](#go-modules). |

**Modules and summary**

Every module is scanned with `govulncheck -show verbose`, from the module's directory, even when a previous one fails. The summary lists, per module, how many vulnerabilities were found at each level:

| Column | Meaning | Fails the check |
|---|---|---|
| `Called` | Your code calls a vulnerable symbol. | Yes |
| `Imported` | A vulnerable package is imported, but none of its vulnerable symbols are called. | No |
| `Required` | A vulnerable module is required, but none of its vulnerable packages are imported. | No |

A module fails when `govulncheck` exits with code `3` (your code calls a vulnerability) or with any code other than `0` (the scan itself failed). After the summary, the failures list the called vulnerabilities of each affected module without their call traces (shown with `--verbose`), or the last lines of the output when the scan failed.

The script exits with code `1` when any module failed.

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

#### `run-build.sh`

Builds the Zig project and copies the build artifacts to the output directory after a successful build.

**Flags**

| Flag | Description |
|---|---|
| `--clean`, `--c` | Cleans up temporary build resources after the build completes. Skips copying the build artifacts to the output directory. |
| `--output=<path>`, `--o=<path>` | Specifies the output directory for the build artifacts. Defaults to `zig-out`. |

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

Runs all Zig tests using `zig build test`. If any test fails, the script exits with an error.

**Flags**

| Flag | Description |
|---|---|
| `--summary`, `--s` | Displays the complete test summary (`all`) instead of only failures (`failures`). |
| `--summary=<value>`, `--s=<value>` | Specifies the test summary level passed to `zig build test --summary`. Defaults to `failures`. |

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
