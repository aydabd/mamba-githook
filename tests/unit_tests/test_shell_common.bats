#!/usr/bin/env bats
###################################################################
# Title: test_shell_common.sh
# Description: This script contains unit tests for shell_common.sh.
#
# Author: Aydin Abdi
###################################################################
set -e

# workaround for lower versions of bats
bats_require_minimum_version "1.5.0" 2>/dev/null || true

# Use MAMBA_GITHOOK_BASE_PATH to override the base path of mamba-githook
MAMBA_GITHOOK_BASE_PATH="${MAMBA_GITHOOK_BASE_PATH:-${MAMBA_GITHOOK_DIR}}"

SCRIPT_NAME="shell_common"

setup() {
  ##############################
  # Setups the test environment.
  ##############################
  # Set the environment variables
  export MAMBA_GITHOOK_VERBOSE="true"

  # Create the test environment
  MAMBA_GITHOOK_BASE_PATH=$(mktemp -d -t "mamba-githook_${SCRIPT_NAME}_test.XXXXXX")
  mkdir -p "${MAMBA_GITHOOK_BASE_PATH}/utils"
  mkdir -p "${MAMBA_GITHOOK_BASE_PATH}/test_library"

  # Copy scripts the files
  cp "./src/utils/__version.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"
  cp "./src/utils/logger.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"
  cp "./src/utils/shell_common.sh" "${MAMBA_GITHOOK_BASE_PATH}/utils/"

  # Copy the test library files
  cp "./tests/libs/mock_helpers.sh" "${MAMBA_GITHOOK_BASE_PATH}/test_library/"

  # Source the shell_common.sh file and mock_helpers.sh
  load "${MAMBA_GITHOOK_BASE_PATH}/utils/shell_common.sh"
  load "${MAMBA_GITHOOK_BASE_PATH}/test_library/mock_helpers.sh"
}

teardown() {
  rm -rf "${MAMBA_GITHOOK_BASE_PATH}" || true
  printf "teardown\n"
}

@test 'sh_cm_detect_shell returns the correct shell' {
  # Mock the `ps` command to return "bash"
  ps() {
    printf "bash\n"
  }
  output=$(sh_cm_detect_shell)
  [ "${output}" = "bash" ]
}

@test 'sh_cm_remove_file returns 0 when the file is removed' {
  # Mock the `rm` command to return 0
  run sh_cm_remove_file "file"
}

@test 'sh_cm_remove_file returns 1 when the file is not removed' {
  # Mock the `rm` command to return 1
  run ! sh_cm_remove_file "file"
}

@test 'sh_cm_remove_dir returns 0 when the directory is removed' {
  # Mock the `rm` command to return 0
  mock_rm_shell_cmd_passes
  sh_cm_remove_dir "dir"
}

@test 'sh_cm_backup_file returns 0 when the file is backed up' {
  temp_file=$(mktemp "${MAMBA_GITHOOK_BASE_PATH}/test_sh_cm_backup_file.XXX")
  temp_dir_path=$(mktemp -d "${MAMBA_GITHOOK_BASE_PATH}/test_sh_cm_backup_file_dir.XXX")
  # Mock the `cp` command to return 0
  mock_cp_shell_cmd_passes
  output=$(sh_cm_backup_file ${temp_file})
  [[ "${output}" =~ "Backed up" ]]

  output=$(sh_cm_backup_file ${temp_file} ${temp_dir_path})
  [[ "${output}" =~ "Backed up" ]]
}

@test 'sh_cm_backup_file returns 1 when the file could not be backed up' {
  temp_file=$(mktemp "${MAMBA_GITHOOK_BASE_PATH}/test_sh_cm_backup_file.XXX")
  temp_dir_path=$(mktemp -d "${MAMBA_GITHOOK_BASE_PATH}/test_sh_cm_backup_file_dir.XXX")
  # Mock the `cp` command to return 1
  mock_cp_shell_cmd_fails
  run ! sh_cm_backup_file ${temp_file}

  run ! sh_cm_backup_file ${temp_file} ${temp_dir_path}
}

@test 'sh_cm_is_file_exist returns 0 when the file exists' {
  temp_file=$(mktemp "${MAMBA_GITHOOK_BASE_PATH}/test_sh_cm_is_file_exist.XXX")
  sh_cm_is_file_exist "${temp_file}"
}

@test 'sh_cm_is_file_exist returns 1 when the file does not exist' {
  run ! sh_cm_is_file_exist "temp_file"
}

@test 'sh_cm_is_dir_exist returns 0 when the directory exists' {
  temp_dir=$(mktemp -d "${MAMBA_GITHOOK_BASE_PATH}/test_sh_cm_is_dir_exist.XXX")
  sh_cm_is_dir_exist ${temp_dir}
}

@test 'sh_cm_is_dir_exist returns 1 when the directory does not exist' {
  run ! sh_cm_is_dir_exist "temp_dir"
}

@test 'sh_cm_mkdir returns 0 when the directory is created' {
  # Mock the `mkdir` command to return 0
  mock_mkdir_shell_cmd_passes
  sh_cm_mkdir "dir"
}

@test 'sh_cm_mkdir returns 1 when the directory is not created' {
  # Mock the `mkdir` command to return 1
  mock_mkdir_shell_cmd_fails
  run ! sh_cm_mkdir "dir"
}

@test 'sh_cm_get_kernel_name returns the correct kernel name' {
  # Mock the `uname` command to return "Linux"
  mock_uname_shell_cmd_passes
  output=$(sh_cm_get_kernel_name)
  [ "${output}" = "Linux" ]
}

@test 'sh_cm_get_kernel_name returns 1 when uname command fails' {
  # Mock the `uname` command to return 1
  mock_uname_shell_cmd_fails
  run ! sh_cm_get_kernel_name
}

@test 'sh_cm_get_machine_hardware_name returns the correct machine hardware name' {
  # Mock the `uname` command to return "x86_64"
  mock_uname_shell_cmd_passes
  output=$(sh_cm_get_machine_hardware_name)
  [ "${output}" = "x86_64" ]
}

@test 'sh_cm_get_machine_hardware_name returns 1 when uname command fails' {
  # Mock the `uname` command to return 1
  mock_uname_shell_cmd_fails
  run ! sh_cm_get_machine_hardware_name
}
