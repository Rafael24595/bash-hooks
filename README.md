## Installer

File name: **_installer-pre-commit_**

By default, the script will be mounted in the same workspace where the installer is located.

**Arguments:**

- **Test**: The script will be mounted inside the remote-scripts directory to prevent it from being used by Git.

    ````bash
    $ ./installer-pre-commit -t
    ````
- **Workspace**: Defines the workspace where the script will be placed.

    ````bash
    $ ./installer-pre-commit --workspace=../other_project/my_project
    ````
- **Output**: Defines directory and name where the script will be placed.

    ````bash
    $ ./installer-pre-commit --output=.test.sh
    ````

## Cleaner

File name: **_clear-resources_**

By default, the script will clean the resources directory of the workspace where the installer is located.

**Arguments:**

- Workspace: Defines the workspace resources directory that will be cleaned.

    ````bash
    $ ./installer-pre-commit --workspace=../other_project/my_project
    ````

## Packages

**Golang:**
>    - **_check-large-files.sh_**: Searches for large files based on a configurable number of bytes.
>    - **_run-formatter.sh_**: Format all Go files.
>    - **_run-linter.sh_**: Runs **_golangci-lint_**  to find errors in staged Go files.
>    - **_run-tests.sh_**: Run all Go tests.