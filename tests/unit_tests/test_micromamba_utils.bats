#!/usr/bin/env bats
#######################################################################
# Title: test_micromamba_utils.sh
# Description: This script contains unit tests for micromamba_utils.sh.
#
# Author: Aydin Abdi
#######################################################################
set -e

# workaround for lower versions of bats
bats_minimum_version=$(bats_require_minimum_version "1.5.0" 2>/dev/null) || true

# Use MAMBA_GITHOOK_BASE_PATH to override the base path of mamba-githook
MAMBA_GITHOOK_BASE_PATH="${MAMBA_GITHOOK_BASE_PATH:-${MAMBA_GITHOOK_DIR}}"

SCRIPT_NAME="micromamba_utils"

setup() {
  ##############################
  # Setups the test environment.
  ##############################
  # Set the environment variables
  export MAMBA_GITHOOK_VERBOSE="true"

  # Create the test environment
  MAMBA_GITHOOK_BASE_PATH=$(mktemp -d -t "mamba-githook_${SCRIPT_NAME}_test.XXXXXX")
  MICROMAMBA_BIN_FOLDER="${MAMBA_GITHOOK_BASE_PATH}/bin"

  mkdir -p "${MICROMAMBA_BIN_FOLDER}"
  mkdir -p "${MAMBA_GITHOOK_BASE_PATH}/utils"
  mkdir -p "${MAMBA_GITHOOK_BASE_PATH}/test_library"

  touch "${MICROMAMBA_BIN_FOLDER}/micromamba"

  # Copy the files
  cp "./src/utils/__version.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"
  cp "./src/utils/logger.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"
  cp "./src/utils/shell_common.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"
  cp "./src/utils/micromamba_utils.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"
  cp "./src/utils/variables.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"

  # Copy the test library files
  cp "./tests/libs/mock_helpers.sh" "${MAMBA_GITHOOK_BASE_PATH}/test_library/"

  # Source the shell_common.sh file and mock_helpers.sh
  load "${MAMBA_GITHOOK_BASE_PATH}/utils/micromamba_utils.sh"
  load "${MAMBA_GITHOOK_BASE_PATH}/test_library/mock_helpers.sh"
}

teardown() {
  rm -r "${MAMBA_GITHOOK_BASE_PATH}"
  printf "Teardown Completed.\n"
}

@test 'mcmamba_utils_is_micromamba_installed returns 0 when micromamba is installed' {
  # mock external 'command' response
  command() { return 0; }
  mcmamba_utils_is_micromamba_installed
}

@test 'mcmamba_utils_is_micromamba_installed returns 1 when micromamba is not installed' {
  # mock external 'command' response
  command() { return 0; }
  rm "${MICROMAMBA_BIN_FOLDER}/micromamba"
  run ! mcmamba_utils_is_micromamba_installed
}

@test '__is_micromamba_shell_init_supported returns 0 when shell is supported' {
  __is_micromamba_shell_init_supported "bash"
  __is_micromamba_shell_init_supported "zsh"
  __is_micromamba_shell_init_supported "fish"
  __is_micromamba_shell_init_supported "xonsh"
}

@test '__is_micromamba_shell_init_supported returns 1 when shell is not supported' {
  run ! __is_micromamba_shell_init_supported "csh"
}

@test '__is_kernel_supported returns 0 when kernel is supported' {
  __is_kernel_supported "Linux"
  __is_kernel_supported "Darwin"
  __is_kernel_supported "Windows NT"
}

@test '__is_kernel_supported returns 1 when kernel is not supported' {
  run ! __is_kernel_supported "FreeBSD"
}

@test '__convert_kernel_name returns "linux" when kernel is "Linux"' {
  output=$(__convert_kernel_name "Linux")
  # Output should be "linux" instead of "Linux"
  [ "${output}" = "linux" ]
}

@test '__convert_kernel_name returns "osx" when kernel is "Darwin"' {
  output=$(__convert_kernel_name "Darwin")
  # Output should be "osx" instead of "Darwin"
  [ "${output}" = "osx" ]
}

@test '__convert_kernel_name returns "win" when kernel is "Windows NT"' {
  output=$(__convert_kernel_name "Windows NT")
  # Output should be "win" instead of "Windows NT"
  [ "${output}" = "win" ]
}

@test '__convert_architecture returns "aarch64" when architecture is "aarch64"' {
  output=$(__convert_architecture "aarch64")
  [ "${output}" = "aarch64" ]
}

@test '__convert_architecture returns "arm64" when architecture is "arm64"' {
  output=$(__convert_architecture "arm64")
  # Output should be "arm64" instead of "aarch64"
  [ "${output}" = "arm64" ]
}

@test '__convert_architecture returns "ppc64le" when architecture is "ppc64le"' {
  output=$(__convert_architecture "ppc64le")
  [ "${output}" = "ppc64le" ]
}

@test '__convert_architecture returns "64" when architecture is "x86_64"' {
  output=$(__convert_architecture "x86_64")
  # Output should be "64" instead of "x86_64"
  [ "${output}" = "64" ]
}

@test '__is_platform_architecture_supported returns 0 when platform-architecture is supported' {
  __is_platform_architecture_supported "linux" "64"
  __is_platform_architecture_supported "linux" "aarch64"
  __is_platform_architecture_supported "linux" "ppc64le"
  __is_platform_architecture_supported "osx" "64"
  __is_platform_architecture_supported "osx" "arm64"
  __is_platform_architecture_supported "win" "64"
}

@test '__is_platform_architecture_supported returns 1 when platform-architecture is not supported' {
  run ! __is_platform_architecture_supported "freebsd" "64"
}

@test '__get_micromamba_url_artifact returns 0 when command is successful' {
  # Mock all external commands used in __get_micromamba_url_artifact
  setup_test__get_micromamba_url_artifact

  output=$(__get_micromamba_url_artifact)
  # Output should be the URL of the latest micromamba release
  [ "${output}" = "https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-linux-64" ]
}

@test '__download_micromamba_artifact returns 0 when command is successful' {
  # Mock all external commands used in __download_micromamba_artifact
  setup_test__download_micromamba_artifact_with_curl

  output=$(__download_micromamba_artifact "/tmp1" "latest")
  [[ "${output}" =~ "Downloaded micromamba to '/tmp1/micromamba'" ]]

  setup_test__download_micromamba_artifact_with_wget

  output=$(__download_micromamba_artifact "/tmp2" "latest")
  [[ "${output}" =~ "Downloaded micromamba to '/tmp2/micromamba'" ]]
}

@test '__download_micromamba_artifact returns 1 when no curl nor wget is found' {
  # Mock all external commands used in __download_micromamba_artifact
  setup_test__download_micromamba_artifact_command_not_found
  run ! __download_micromamba_artifact "/tmp" "latest"
}

@test '__download_micromamba_artifact returns 1 when curl or wget fails' {
  # Mock all external commands used in __download_micromamba_artifact
  setup_test__download_micromamba_artifact_with_curl

  # Mocked curl command
  curl() { return 1; }
  run ! __download_micromamba_artifact "/tmp" "latest"

  setup_test__download_micromamba_artifact_with_wget

  # Mocked wget command
  wget() { return 1; }
  run ! __download_micromamba_artifact "/tmp" "latest"
}
