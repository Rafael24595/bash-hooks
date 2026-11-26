#!/bin/bash
#
# Behaviour tests for the bash-hooks installer.
#
# Usage: test/bash-hooks.test.sh [path/to/bash-hooks]
#
# Every test runs in its own temporary directory with a private copy of the
# installer, so nothing in the repository (or the real installer) is touched.
# Requires the same tools as the installer itself (bash, yq v4).

set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Import assertions from assert.sh
# shellcheck disable=SC1091
source "$HERE/sources/assert.sh"
# Import runner from runner.sh
# shellcheck disable=SC1091
source "$HERE/sources/runner.sh"

resolve_sut() {
    local candidate=${1:-"$HERE/../bash-hooks"}

    if [[ ! -f "$candidate" ]]; then
        echo "Error: installer not found at '$candidate' (expected a file)." >&2
        echo "Usage: $(basename "$0") [path/to/bash-hooks]" >&2
        exit 2
    fi

    realpath "$candidate"
}

if ! SUT_SOURCE="$(resolve_sut "$@")"; then
    exit 2
fi

# Set by setup for every test.
SUT=""
STUBS=""

# Sandbox: a private copy of the installer, a stubs dir that shadows PATH,
# and an empty workspace as the working directory.
setup() {
    if ! mkdir -p bin stubs ws; then
        return 1
    fi

    if ! cp "$SUT_SOURCE" bin/bash-hooks; then
        return 1
    fi

    SUT="$TEST_TMP/bin/bash-hooks"
    STUBS="$TEST_TMP/stubs"

    if ! cd ws; then
        return 1
    fi
}

# -------- #
# FIXTURES #
# -------- #

run_sut() {
    run env PATH="$STUBS:$PATH" bash "$SUT" "$@"
}

# write_script <path> <exit code>
write_script() {
    local path=$1
    local code=$2

    mkdir -p "$(dirname "$path")"
    printf '#!/bin/bash\nexit %s\n' "$code" > "$path"
    chmod +x "$path"
}

# write_config <file> <id:path[:disabled]>...
write_config() {
    local file=$1
    shift

    {
        echo "hooks:"
        echo "  local:"
        echo "    scripts:"

        local entry
        local id
        local path
        local disabled

        for entry in "$@"; do
            IFS=':' read -r id path disabled <<< "$entry"

            echo "      - id: $id"
            echo "        path: $path"

            if [[ "$disabled" == "disabled" ]]; then
                echo "        disabled: true"
            fi
        done
    } > "$file"
}

# Workspace with one passing and one failing local script.
given_workspace_with_scripts() {
    write_script scripts/ok.sh 0
    write_script scripts/ko.sh 1
    write_config pre-commit-build.yml "ok-check:./scripts/ok.sh" "ko-check:./scripts/ko.sh"
}

given_existing_hook() {
    mkdir -p .git/hooks
    printf '#!/bin/bash\necho previous hook\n' > .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit
}

# Replaces curl with a stub that always fails (no network in tests).
given_offline() {
    printf '#!/bin/bash\nexit 22\n' > "$STUBS/curl"
    chmod +x "$STUBS/curl"
}

run_hook() {
    ./.git/hooks/pre-commit > /dev/null 2>&1
}

PREVIOUS_HOOK=$'#!/bin/bash\necho previous hook'

# ----- #
# BUILD #
# ----- #

test_build_generates_executable_hook() {
    write_script scripts/ok.sh 0
    write_config pre-commit-build.yml "ok-check:./scripts/ok.sh"

    run_sut

    assert_status 0
    assert_file_exists .git/hooks/pre-commit
    assert_executable .git/hooks/pre-commit
    assert_file_contains .git/hooks/pre-commit "HOOK_OK_CHECK=true"
    assert_file_contains .git/hooks/pre-commit "./scripts/ok.sh"
}

test_build_accepts_yaml_extension() {
    write_script scripts/ok.sh 0
    write_config pre-commit-build.yaml "ok-check:./scripts/ok.sh"

    run_sut

    assert_status 0
    assert_file_contains .git/hooks/pre-commit "HOOK_OK_CHECK=true"
}

test_build_uses_input_flag() {
    write_script scripts/ok.sh 0
    write_config custom.yml "ok-check:./scripts/ok.sh"

    run_sut --input=custom.yml

    assert_status 0
    assert_file_contains .git/hooks/pre-commit "HOOK_OK_CHECK=true"
}

test_build_resolves_input_and_output_inside_workspace() {
    mkdir sub

    write_script sub/scripts/ok.sh 0
    write_config sub/pre-commit-build.yml "ok-check:./scripts/ok.sh"

    run_sut --workspace=sub

    assert_status 0
    assert_file_contains sub/.git/hooks/pre-commit "HOOK_OK_CHECK=true"
    assert_file_missing .git/hooks/pre-commit
}

test_build_skips_disabled_scripts() {
    write_script scripts/ok.sh 0
    write_script scripts/ko.sh 1
    write_config pre-commit-build.yml "ok-check:./scripts/ok.sh" "ko-check:./scripts/ko.sh:disabled"

    run_sut

    assert_status 0
    assert_file_contains .git/hooks/pre-commit "HOOK_OK_CHECK=true"
    assert_file_not_contains .git/hooks/pre-commit "HOOK_KO_CHECK"
}

test_build_test_mode_does_not_touch_git_hook() {
    given_existing_hook
    write_script scripts/ok.sh 0
    write_config pre-commit-build.yml "ok-check:./scripts/ok.sh"

    run_sut --test

    assert_status 0
    assert_file_equals .git/hooks/pre-commit "$PREVIOUS_HOOK"
    assert_file_contains .remote-scripts/.temp/.pre-commit "HOOK_OK_CHECK=true"
}

test_build_fails_without_input_file() {
    run_sut

    assert_status 1
    assert_contains "$STDERR" "No input file found" "stderr"
    assert_no_bash_error
}

test_build_fails_with_multiple_input_files() {
    write_config pre-commit-build.yml
    write_config pre-commit-build.yaml

    run_sut

    assert_status 1
    assert_contains "$STDERR" "Multiple input files found" "stderr"
    assert_no_bash_error
}

test_build_fails_with_invalid_yaml() {
    printf 'hooks: [\n' > pre-commit-build.yml

    run_sut

    assert_status 1
    assert_contains "$STDERR" "Invalid YAML format" "stderr"
}

test_build_fails_when_local_script_is_missing() {
    write_config pre-commit-build.yml "ghost:./scripts/ghost.sh"

    run_sut

    assert_status 1
    assert_contains "$STDERR" "does not exist" "stderr"
}

# Regression: a failed build must not wipe a working hook.
test_build_without_input_keeps_existing_hook() {
    given_existing_hook

    run_sut

    assert_status 1
    assert_file_equals .git/hooks/pre-commit "$PREVIOUS_HOOK"
}

test_build_with_invalid_yaml_keeps_existing_hook() {
    given_existing_hook
    printf 'hooks: [\n' > pre-commit-build.yml

    run_sut

    assert_status 1
    assert_file_equals .git/hooks/pre-commit "$PREVIOUS_HOOK"
}

test_build_failing_midway_keeps_existing_hook() {
    given_existing_hook
    write_script scripts/ok.sh 0
    write_config pre-commit-build.yml "ok-check:./scripts/ok.sh" "ghost:./scripts/ghost.sh"

    run_sut

    assert_status 1
    assert_file_equals .git/hooks/pre-commit "$PREVIOUS_HOOK"
    assert_file_missing .git/hooks/pre-commit.tmp
}

test_successful_build_leaves_no_temporary_file() {
    write_script scripts/ok.sh 0
    write_config pre-commit-build.yml "ok-check:./scripts/ok.sh"

    run_sut

    assert_status 0
    assert_file_missing .git/hooks/pre-commit.tmp
}

test_state_change_leaves_no_temporary_file() {
    given_workspace_with_scripts
    run_sut

    run_sut --disable

    assert_status 0
    assert_file_missing .git/hooks/pre-commit.tmp
}

# -------------- #
# GENERATED HOOK #
# -------------- #

test_generated_hook_passes_when_scripts_succeed() {
    write_script scripts/ok.sh 0
    write_config pre-commit-build.yml "ok-check:./scripts/ok.sh"

    run_sut
    assert_status 0

    run_hook || fail "hook failed although every script succeeded"
}

test_generated_hook_fails_when_a_script_fails() {
    given_workspace_with_scripts

    run_sut
    assert_status 0

    if run_hook; then
        fail "hook succeeded although a script failed"
    fi
}

# ----------- #
# HOOKS STATE #
# ----------- #

test_disable_whole_hook() {
    given_workspace_with_scripts

    run_sut
    assert_status 0

    run_sut --disable

    assert_status 0
    assert_executable .git/hooks/pre-commit
    assert_file_contains .git/hooks/pre-commit "DISABLED_HOOK=true"

    run_hook || fail "disabled hook still runs its scripts"
}

test_enable_whole_hook() {
    given_workspace_with_scripts

    run_sut
    run_sut --disable

    run_sut --enable

    assert_status 0
    assert_executable .git/hooks/pre-commit
    assert_file_contains .git/hooks/pre-commit "DISABLED_HOOK=false"
    if run_hook; then
        fail "enabled hook did not run its scripts"
    fi
}

test_disable_single_script() {
    given_workspace_with_scripts

    run_sut
    assert_status 0

    run_sut --disable=ko-check

    assert_status 0
    assert_executable .git/hooks/pre-commit
    assert_file_contains .git/hooks/pre-commit "HOOK_KO_CHECK=false"
    assert_file_contains .git/hooks/pre-commit "HOOK_OK_CHECK=true"
    run_hook || fail "disabled script still runs"
}

test_state_change_does_not_require_input_file() {
    given_workspace_with_scripts

    run_sut
    rm pre-commit-build.yml

    run_sut --disable

    assert_status 0
    assert_file_contains .git/hooks/pre-commit "DISABLED_HOOK=true"
}

test_state_change_without_hook_fails_and_creates_nothing() {
    run_sut --disable

    assert_status_not 0
    assert_file_missing .git/hooks/pre-commit
}

test_build_generates_enabled_hook() {
    given_workspace_with_scripts

    run_sut

    assert_status 0
    assert_file_contains .git/hooks/pre-commit "DISABLED_HOOK=false"
}

test_disable_several_scripts_at_once() {
    given_workspace_with_scripts
    run_sut

    run_sut --disable=ok-check,ko-check

    assert_status 0
    assert_file_contains .git/hooks/pre-commit "HOOK_OK_CHECK=false"
    assert_file_contains .git/hooks/pre-commit "HOOK_KO_CHECK=false"
}

test_enable_and_disable_different_scripts() {
    given_workspace_with_scripts
    run_sut
    run_sut --disable=ok-check

    run_sut --enable=ok-check --disable=ko-check

    assert_status 0
    assert_file_contains .git/hooks/pre-commit "HOOK_OK_CHECK=true"
    assert_file_contains .git/hooks/pre-commit "HOOK_KO_CHECK=false"
}

test_unknown_script_id_fails_without_changes() {
    given_workspace_with_scripts
    run_sut

    local before
    before="$(<.git/hooks/pre-commit)"

    run_sut --disable=typo

    assert_status_not 0
    assert_file_equals .git/hooks/pre-commit "$before"
    assert_file_missing .git/hooks/pre-commit.tmp
}

test_global_and_single_state_flags_are_rejected() {
    given_workspace_with_scripts
    run_sut

    run_sut --enable --disable=ko-check

    assert_status 2
    assert_file_contains .git/hooks/pre-commit "HOOK_KO_CHECK=true"
}

test_enable_and_disable_whole_hook_are_rejected() {
    given_workspace_with_scripts
    run_sut

    run_sut --enable --disable

    assert_status 2
    assert_file_contains .git/hooks/pre-commit "DISABLED_HOOK=false"
}

test_single_then_global_state_flags_are_rejected() {
    given_workspace_with_scripts
    run_sut

    run_sut --disable=ko-check --enable

    assert_status 2
    assert_file_contains .git/hooks/pre-commit "HOOK_KO_CHECK=true"
}

# ------ #
# UPDATE #
# ------ #

test_update_does_not_require_input_file() {
    given_offline

    run_sut --update

    assert_not_contains "$STDERR" "No input file found" "stderr"
    assert_contains "$STDERR" "Failed to retrieve" "stderr"
}

test_update_does_not_create_git_hook() {
    given_offline

    run_sut --update

    assert_file_missing .git/hooks/pre-commit
    assert_no_bash_error
}

# Regression: the original report (an unrelated error wiping the hook).
test_failed_update_keeps_existing_hook() {
    given_existing_hook
    given_offline

    run_sut --update

    assert_file_equals .git/hooks/pre-commit "$PREVIOUS_HOOK"
}

# ---- #
# MISC #
# ---- #

test_unknown_option_exits_with_status_2() {
    run_sut --nope

    assert_status 2
}

test_version_does_not_touch_workspace() {
    run_sut --version

    assert_status 0

    if [[ -n "$(ls -A)" ]]; then
        fail "workspace is not empty after --version"
    fi
}

echo -e "\nTesting ${SUT_SOURCE}\n"
run_tests
