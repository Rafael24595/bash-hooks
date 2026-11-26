#!/bin/bash
#
# Generic assertions for bash tests.
#
# Contract: `run <cmd...>` executes a command and stores its result in
# STATUS, STDOUT and STDERR. Assertions about a command's result read those
# variables; file assertions take explicit paths. A failed assertion prints
# its message and exits the current (sub)shell with status 1.

STATUS=0
STDOUT=""
STDERR=""

run() {
    local out_file
    local err_file

    out_file="$(mktemp)"
    err_file="$(mktemp)"

    "$@" > "$out_file" 2> "$err_file" < /dev/null
    STATUS=$?

    # shellcheck disable=SC2034
    STDOUT="$(<"$out_file")"
    STDERR="$(<"$err_file")"

    rm -f "$out_file" "$err_file"
}

fail() {
    echo "    FAIL: $1" >&2

    if [[ -n "$STDERR" ]]; then
        echo "    --- stderr of last run ---" >&2
        # shellcheck disable=SC2001
        sed 's/^/    /' <<< "$STDERR" >&2
    fi

    exit 1
}

# --------------- #
# COMMAND RESULTS #
# --------------- #

assert_status() {
    local expected=$1
    if (( STATUS != expected )); then
        fail "expected exit status $expected, got $STATUS"
    fi
}

assert_status_not() {
    local unexpected=$1
    if (( STATUS == unexpected )); then
        fail "expected exit status other than $unexpected"
    fi
}

assert_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    if [[ "$haystack" != *"$needle"* ]]; then
        fail "$label does not contain '$needle'"
    fi
}

assert_not_contains() {
    local haystack=$1
    local needle=$2
    local label=$3

    if [[ "$haystack" == *"$needle"* ]]; then
        fail "$label unexpectedly contains '$needle'"
    fi
}

assert_no_bash_error() {
    # Errors raised by bash itself look like "<script>: line N: ...".
    if grep -Eq ': line [0-9]+: ' <<< "$STDERR"; then
        fail "stderr contains a raw bash error"
    fi
}

# ----- #
# FILES #
# ----- #

assert_file_exists() {
    if [[ ! -f "$1" ]]; then
        fail "file '$1' does not exist"
    fi
}

assert_file_missing() {
    if [[ -e "$1" ]]; then
        fail "file '$1' should not exist"
    fi
}

assert_executable() {
    if [[ ! -x "$1" ]]; then
        fail "file '$1' is not executable"
    fi
}

assert_file_contains() {
    local file=$1
    local needle=$2

    if ! grep -qF -- "$needle" "$file"; then
        fail "file '$file' does not contain '$needle'"
    fi
}

assert_file_not_contains() {
    local file=$1
    local needle=$2

    if grep -qF -- "$needle" "$file"; then
        fail "file '$file' unexpectedly contains '$needle'"
    fi
}

assert_file_equals() {
    local file=$1
    local expected=$2

    if [[ "$(<"$file")" != "$expected" ]]; then
        fail "file '$file' does not have the expected content"
    fi
}
