#!/usr/bin/env bats
########################################################################
# Title: test_options
# Description: This script contains integration tests for mamba-githook.
#
# Author: Aydin Abdi
########################################################################
set -e

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
  printf "Setup Completed.\n"
}

teardown() {
  printf "Teardown Completed.\n"
}

@test 'mamba-githook --version returns the correct version' {
  output=$(mamba-githook --version)
  [ "$output" = "1.0.0" ]

  output=$(mamba-githook -v)
  [ "$output" = "1.0.0" ]
}

@test 'mamba-githook --help returns the help message' {
  mamba-githook --help
  mamba-githook -h
}

@test 'mamba-githook wrong option returns 1' {
  run ! mamba-githook --wrong-option
}
