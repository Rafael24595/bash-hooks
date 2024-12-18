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
>    - **_check-large-files.sh_**: Searches for large files based on a configurable number of bytes.
>       - **Arguments**: 
>           - _File size in bytes. Example: **5242880**_ 
>    - **_run-formatter.sh_**: Format all Go files.
>    - **_run-linter.sh_**: Runs **_golangci-lint_**  to find errors in staged Go files.
>       - **Depencencies**: 
>           - **_golangci-lint_** -  _1.62.0_ (https://github.com/golangci/golangci-lint)
>    - **_run-tests.sh_**: Run all Go tests.

**Shell:**
>    - **_run-linter.sh_**: Runs **_shellcheck_**  to find errors in staged Shell files.
>       - **Depencencies**: 
>           - **_shellcheck_** -  _0.8.0_ (https://www.shellcheck.net)

## Dependencies

- **yq** -  _v4.44.2_ (https://github.com/mikefarah/yq)
    - **Notes**: **_snap_** installations of **_yq_** could not working as expected. See: [snap-notes](https://github.com/mikefarah/yq/#snap-notes)
