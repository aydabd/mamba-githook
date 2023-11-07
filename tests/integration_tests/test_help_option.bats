########################################################################
# Title: test_help_options
# Description: This file contains the test cases for the help options.
#
# Author: Aydin Abdi
########################################################################
set -e # Enable the debug mode

# workaround for lower versions of bats
bats_require_minimum_version "1.5.0" 2>/dev/null || true

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
  printf "Setup Completed.\n"
}

teardown() {
  printf "Teardown Completed.\n"
}

@test "test mamba-githook help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook -h
  mamba-githook --help
}

@test "test mamba-githook init-project help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook init-project -h
  mamba-githook init-project --help
}

@test "test mamba-githook deinit-project help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook deinit-project -h
  mamba-githook deinit-project --help
}

@test "test mamba-githook init-global-hookspath help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook init-global-hookspath -h
  mamba-githook init-global-hookspath --help
}

@test "test mamba-githook deinit-global-hookspath help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook deinit-global-hookspath -h
  mamba-githook deinit-global-hookspath --help
}

@test "test mamba-githook install-micromamba help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook install-micromamba -h
  mamba-githook install-micromamba --help
}

@test "test mamba-githook uninstall-micromamba help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook uninstall-micromamba -h
  mamba-githook uninstall-micromamba --help
}

@test "test mamba-githook run-hooks help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ###############################################
  mamba-githook run-hooks -h
  mamba-githook run-hooks --help
}

@test "test mamba-githook init-shell help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook init-shell -h
  mamba-githook init-shell --help
}

@test "test mamba-githook adhoc-shell help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mamba-githook adhoc-shell -h
  mamba-githook adhoc-shell --help
}

@test "test mamba-githook micromamba-run help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################

  mamba-githook micromamba-run -h
  mamba-githook micromamba-run --help
}

@test "test mamba-githook micromamba-create-env help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ###############################################

  mamba-githook micromamba-create-env -h
  mamba-githook micromamba-create-env --help
}

@test "test mamba-githook mcmamba-cmd help option" {
  ################################################
  # Tests the help option.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ###############################################

  mamba-githook mcmamba-cmd -h
  mamba-githook mcmamba-cmd --help
}
