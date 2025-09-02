## Configuration file

The configuration file must be named [**_pre-commit-build.yaml_**](https://github.com/Rafael24595/bash-hooks/blob/main/pre-commit-build.template.yaml) by default and placed in the root of the project workspace with the following structure:

- Root tag "**_hooks_**" (_Required_):
    - For remote scripts, use a "**_remote_**" tag that contains a list of "**_repos_**" with the following structure:
        - **id**: The ID of the script.
        - **origin**: The URL of the GitHub repository.
        - **tag**: The tag of the repository.
        - **target**: The path that contains the script.
        - **name**: The name of the script.
        - **expect**: The expected result of the script — `true` for exit code `0`, `false` for exit code `< 1`.
        - **return**: The actual return value of the script. `true` for `1`, `false` for `0`.
        - **flags**: The flags passed to the script, defined without the `--` prefix.
        - **args**: The arguments passed to the script.
    - For local scripts, use a "**_local_**" tag that contains a list of "**_scripts_**" with the following structure:
        - **id**: The ID of the script.
        - **path**: The path that contains the script.
        - **expect**: The expected result of the script — `true` for exit code `0`, `false` for exit code `< 1`.
        - **return**: The actual return value of the script. `true` for `1`, `false` for `0`.
        - **flags**: The flags passed to the script, defined without the `--` prefix.
        - **args**: The arguments passed to the script.

**_See the template example:_** [**_pre-commit-build.template.yaml_**](https://github.com/Rafael24595/bash-hooks/blob/main/pre-commit-build.template.yaml)

## Installer

File name: **_install-pre-commit_**

By default, the script will be mounted in the same workspace where the installer is located.

**Arguments:**

- **Help**: Help command.

    ````bash
    $ ./install-pre-commit -h
    ````
    ````bash
    $ ./install-pre-commit --help
    ````

- **Update**: Updates the installer to the defined version. If a version is not specified, it will be updated to the latest version.

    ````bash
    $ ./install-pre-commit -u
    ````
    ````bash
    $ ./install-pre-commit --update=tag
    ````

- **Version**: Shows actual installer version.

    ````bash
    $ ./install-pre-commit -v
    ````
    ````bash
    $ ./install-pre-commit --version
    ````
- **Test**: The script will be mounted inside the remote-scripts directory to prevent it from being used by Git.

    ````bash
    $ ./install-pre-commit -t
    ````
- **Workspace**: Defines the workspace where the script will be placed.

    ````bash
    $ ./install-pre-commit --workspace=../other_project/my_project
    ````
- **Input**: Defines the directory and name where the input file is located.

    ````bash
    $ ./install-pre-commit --input=.test.yaml
    ````

- **Output**: Defines directory and name where the script will be placed.

    ````bash
    $ ./install-pre-commit --output=.test.sh
    ````

- **Block**: Generates the script as a single file without imports.

    ````bash
    $ ./install-pre-commit -b
    ````
    ````bash
    $ ./install-pre-commit --block
    ````

- **Mode**: Specifies the build mode. Default is pre_commit. Valid options: pre_commit, pre_push.

    ````bash
    $ ./install-pre-commit --mode=pre_commit
    ````

- **Pull**: Downloads the specified remote script at the given version.

    ````bash
    $ ./install-pre-commit --pull=golang/sh/run-govulncheck.sh:0.6.3
    ````

## Cleaner

File name: **_clear-resources_**

By default, the script will clean the resources directory of the workspace where the installer is located.

**Arguments:**

- Workspace: Defines the workspace resources directory that will be cleaned.

    ````bash
    $ ./clear-resources --workspace=../other_project/my_project
    ````

## Packages

**Golang:**
>    - **check-go-context.sh**: Executes functions to validate whether the current project is a valid Go project.
>       - **Flags**: 
>           - **If none are selected, all checks will be executed**
>           - **--project** | **-p**: Verifies if this is a Go project
>           - **--staged** | **-s**: Checks for staged Go files
>           - **--install** | **-i**: Verifies if Go is installed
>    - **run-formatter.sh**: Format all Go files.
>    - **run-linter.sh**: Runs **_golangci-lint_**  to find errors in staged Go files.
>       - **Flags**: 
>           - **--install**: Installs the latest version of golangci-lint if it is not already 
>       - **Dependencies**: 
>           - **_golangci-lint_** -  _1.62.0_ (https://github.com/golangci/golangci-lint)
>    - **run-tests.sh**: Runs all Go tests.
>    - **run-govulncheck.sh**: Executes govulncheck to check for vulnerabilities in dependencies.
>       - **Flags**: 
>           - **--install**: Installs the latest version of govulncheck if it is not already installed
>       - **Dependencies**: 
>           - **_govulncheck_** -  _v1.1.4_ (https://github.com/golang/vuln)
>    - **run-coverage-black-box.sh**: Runs black-box tests on Go packages and calculates code coverage. By default, it checks whether the test directory structure matches the source structure and verifies if the current test coverage meets or exceeds the specified minimum.
>       - **Flags**: 
>           - **--verbose** | **--v** : Displays the coverage details.
>           - **--success-empty** | **--se** : Treats the absence of tests as a successful result.
>           - **--invalid-empty** | **--ie** : Treats packages with no found tests as a valid result.
>           - **--package=`<pkg>`** | **--p=`<pkg>`** : Manually specify one or more packages to analyze. Can be repeated to include multiple packages.
>       - **Arguments**: 
>           - _Minimum coverage percentage. Example: **80.0**_ 

**Node:**
>    - **run-npm-run.sh**: Executes an npm script command based on a configurable argument.
>       - **Arguments**: 
>           - _Script command. Example: **build**, **dev**, **test**..._
>       - **Dependencies**: 
>           - **_node_** - Tested with Node.js v18+, but should work with all versions (https://nodejs.org/en)

**Elixir/Mix:**
>    - **check-mix-context.sh**: Executes functions to validate whether the current project is a valid Mix project.
>       - **Flags**: 
>           - **If none are selected, all checks will be executed**
>           - **--project** | **-p**: Verifies if this is a Mix project
>           - **--staged** | **-s**: Checks for staged Elixir files (`*.ex` / `*.exs`)
>           - **--install** | **-i**: Verifies if Elixir and Mix are installed
>    - **run-mix-tests.sh**: Executes all Mix tests.
>       - **Dependencies**: 
>           - **_Mix_** - _^1.12.0_ (https://hexdocs.pm/mix/Mix.Tasks.Test.html)
>    - **run-credo.sh**: Executes Credo analysis tool to analyze code consistency and identify errors.
>       - **Flags**: 
>           - **--static** | **-s**: Includes all issues. Without it, only positive-priority issues (↑ ↗ →) will be reported
>       - **Dependencies**: 
>           - **_Credo_** - _v1.7.12_ (https://hexdocs.pm/credo/overview.html)

**Shell:**
>    - **run-linter.sh**: Runs **_shellcheck_**  to find errors in staged Shell files.
>       - **Dependencies**: 
>           - **_shellcheck_** -  _0.8.0_ (https://www.shellcheck.net)

**Tools:**
>    - **check-large-files.sh**: Searches for large files based on a configurable number of bytes.
>       - **Arguments**: 
>           - _File size in bytes. Example: **5242880**_ 

## Dependencies

- **yq** -  _v4.44.2_ (https://github.com/mikefarah/yq)
    - **Notes**: **_snap_** installations of **_yq_** could not working as expected. See: [snap-notes](https://github.com/mikefarah/yq/#snap-notes)
