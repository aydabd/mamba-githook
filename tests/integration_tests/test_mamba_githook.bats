#!/usr/bin/env bats
########################################################################
# Title: test_mamba_githook
# Description: This script contains integration tests for mamba-githook.
#
# Author: Aydin Abdi
########################################################################
set -e # Enable the debug mode

# workaround for lower versions of bats
bats_require_minimum_version "1.5.0" 2>/dev/null || true

setup() {
  ##############################
  # Setups the test environment.
  ##############################
  # Set the environment variables
  export MAMBA_GITHOOK_VERBOSE="true"

  # Check mamba-githook is installed
  if ! command -v mamba-githook >/dev/null; then
    printf "mamba-githook could not be found"
    return 1
  fi

  # Load test helpers
  load ../libs/mock_helpers.sh

  # Setup the test environment
  setup_test
  printf "Setup Completed.\n"
}

teardown() {
  git_config_global_unset_core_hookspath

  if check_micromamba_installed >/dev/null; then
    printf "Uninstall micromamba.\n"
    mamba-githook -V uninstall-micromamba --yes || {
      printf "Failed to uninstall micromamba.\n"
      return 0
    }
  fi
  rm_temp_dir "${test_dir}"
  # Change back to home directory
  change_to_test_dir "${HOME}"
  printf "Teardown Completed.\n"
}

setup_test() {
  ################################################
  # Setups the test environment.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  test_dir=$(create_temp_test_directory)
  change_to_test_dir "${test_dir}"
  git_init_main
  git_config_user
}

@test 'test init-project modifies the git core hookspath' {
  mamba-githook -V init-project
  [ "$(git_config_get_core_hookspath)" == "/usr/share/mamba-githook/hooks" ]
}

@test 'test init-project --create-sample creates a sample project' {
  mamba-githook -V init-project --create-sample
  [ -d ".githooks.d" ]
  [ -f ".githooks.d/.pre-commit-config.yaml" ]
  [ -f ".githooks.d/pre-commit_environment.yml" ]
  [ -f ".githooks.d/pre-commit.10.pre_commit" ]
  [ -f ".githooks.d/pre-push.10.jira" ]
  [ $(git_config_get_core_hookspath) == "/usr/share/mamba-githook/hooks" ]
}

@test 'test init-global-hookspath modifies the git core hookspath' {
  mamba-githook -V init-global-hookspath
  [ "$(git_config_get_core_hookspath --global)" == "/usr/share/mamba-githook/hooks" ]
}

@test 'test deinit-project removes the git core hookspath' {
  # Set the git core hookspath
  mamba-githook -V init-project

  # Remove the git core hookspath
  mamba-githook -V deinit-project
  [ "$(git_config_get_core_hookspath)" == "" ]
}

@test 'test deinit-project --delete-sample removes the sample project' {
  # Create a sample project
  mamba-githook -V init-project --create-sample

  # Remove the sample project
  mamba-githook -V deinit-project --delete-sample
  [ ! -d ".githooks.d" ]
}

@test 'test deinit-global-hookspath removes the git core hookspath' {
  # Set the git core hookspath
  mamba-githook -V init-global-hookspath

  # Remove the git core hookspath
  mamba-githook -V deinit-global-hookspath
  [ "$(git_config_get_core_hookspath --global)" == "" ]
}

@test 'test install-micromamba without arguments reads from input' {
  mamba-githook install-micromamba <<<"y"
}

@test 'test uninstall-micromamba without arguments reads from input' {
  mamba-githook uninstall-micromamba <<<"y"
}

@test 'test install and uninstall Micromamba' {
  # Install micromamba
  mamba-githook -V install-micromamba --yes

  # Uninstall micromamba
  mamba-githook -V uninstall-micromamba --yes
}

@test 'test pre-commit hook' {
  # Create a sample project into the git repository
  mamba-githook init-project --create-sample

  # Add all files
  git add -A

  # Commit the files
  git commit -m "Add files"
}
