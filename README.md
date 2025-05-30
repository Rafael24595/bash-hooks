## Configuration file

The configuration file must be named [**_pre-commit-build.yaml_**](https://github.com/Rafael24595/bash-hooks/blob/main/pre-commit-build.template.yaml) by default and placed in the root of the project workspace with the following structure:

- Root tag "**_hooks_**" (_Required_):
    - For remote scripts, use a "**_remote_**" tag that contains a list of "**_repos_**" with the following structure:
        - **id**: The ID of the script.
        - **origin**: The URL of the GitHub repository.
        - **tag**: The tag of the repository.
        - **target**: The path that contains the script.
        - **name**: The name of the script.
    - For local scripts, use a "**_local_**" tag that contains a list of "**_scripts_**" with the following structure:
        - **id**: The ID of the script.
        - **path**: The path that contains the script.

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

- **Mode**: Specifies the build mode. Default is pre_commit. Valid options: pre_commit, pre_push.

    ````bash
    $ ./install-pre-commit --mode=pre_commit
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
>           - **--project**: Verifies if this is a Go project
>           - **--staged**: Checks for staged Go files
>           - **--install**: Verifies if Go is installed
>    - **check-large-files.sh**: Searches for large files based on a configurable number of bytes.
>       - **Arguments**: 
>           - _File size in bytes. Example: **5242880**_ 
>    - **run-formatter.sh**: Format all Go files.
>    - **run-linter.sh**: Runs **_golangci-lint_**  to find errors in staged Go files.
>       - **Flags**: 
>           - **--install**: Installs the latest version of golangci-lint if it is not already 
>       - **Dependencies**: 
>           - **_golangci-lint_** -  _1.62.0_ (https://github.com/golangci/golangci-lint)
>    - **run-tests.sh**: Run all Go tests.
>    - **run-govulncheck.sh**: Executes govulncheck to check for vulnerabilities in dependencies.
>       - **Flags**: 
>           - **--install**: Installs the latest version of govulncheck if it is not already installed
>       - **Dependencies**: 
>           - **_govulncheck_** -  _v1.1.4_ (https://github.com/golang/vuln)

**Node:**
>    - **run-npm-run.sh**: Executes an npm script command based on a configurable argument.
>       - **Arguments**: 
>           - _Script command. Example: **build**, **dev**, **test**..._
>       - **Dependencies**: 
>           - **_node_** -  – tested with Node.js v18+, but should work with all versions (https://nodejs.org/en)


**Shell:**
>    - **run-linter.sh**: Runs **_shellcheck_**  to find errors in staged Shell files.
>       - **Dependencies**: 
>           - **_shellcheck_** -  _0.8.0_ (https://www.shellcheck.net)

## Dependencies

- **yq** -  _v4.44.2_ (https://github.com/mikefarah/yq)
    - **Notes**: **_snap_** installations of **_yq_** could not working as expected. See: [snap-notes](https://github.com/mikefarah/yq/#snap-notes)
