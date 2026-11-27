#!/bin/bash
#
# Generic test runner.
#
# run_tests discovers every function named test_* and runs each one in its own
# subshell, with a fresh temporary directory as working directory (TEST_TMP).
# If the test file defines `setup`, it runs inside that subshell before the
# test. A failing setup is an infrastructure error: the whole run aborts
# instead of reporting misleading results.
#
# Set TEST_FILTER to run only the tests whose name contains it.

# Returns 0 if the test passed, 1 if it failed, 2 if its setup failed.
# Setup failures are flagged with a marker file rather than an exit code, so
# that a test whose last command happens to return 2 is not mistaken for one.
_run_single_test() {
    local name=$1

    local root
    local status
    local setup_failed

    if ! root="$(mktemp -d)"; then
        return 2
    fi

    if ! mkdir "$root/work"; then
        rm -rf "$root"
        return 2
    fi

    (
        TEST_TMP="$root/work"

        if ! cd "$TEST_TMP"; then
            touch "$root/.setup_failed"
            exit 1
        fi

        if declare -F setup > /dev/null && ! setup; then
            touch "$root/.setup_failed"
            exit 1
        fi

        "$name"
    )

    status=$?

    setup_failed=false
    if [[ -e "$root/.setup_failed" ]]; then
        setup_failed=true
    fi

    rm -rf "$root"

    if [[ "$setup_failed" == true ]]; then
        return 2
    fi

    if (( status == 0 )); then
        return 0
    fi

    return 1
}

run_tests() {
    local filter=${TEST_FILTER:-}

    local passed=0
    local failed=0
    local failed_names=()

    local name
    local status

    while read -r name; do
        if [[ -n "$filter" && "$name" != *"$filter"* ]]; then
            continue
        fi

        _run_single_test "$name"
        status=$?

        case $status in
            0)
                echo "  ok   $name"
                passed=$((passed + 1))
                ;;
            2)
                echo "Error: setup failed for '$name'; aborting." >&2
                return 2
                ;;
            *)
                echo "  FAIL $name"
                failed=$((failed + 1))
                failed_names+=("$name")
                ;;
        esac
    done < <(declare -F | awk '$3 ~ /^test_/ { print $3 }')

    echo -e "\n${passed} passed, ${failed} failed"

    if (( failed > 0 )); then
        printf '  - %s\n' "${failed_names[@]}" && echo
        return 1
    fi

    echo
}
