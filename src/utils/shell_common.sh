###########################################################
# Title: shell_common.sh
# Description: This script contains common shell functions.
# Public method names starts with 'sh_cm_' prefix.
#
# Author: Aydin Abdi
#
# Usage:
#   'source shell_common.sh' or '. shell_common.sh'
#   sh_cm_detect_shell
#   sh_cm_remove_file <file>
#   sh_cm_remove_dir <dir>
###########################################################
set -e

# Use MAMBA_GITHOOK_BASE_PATH to override the base path of mamba-githook
MAMBA_GITHOOK_BASE_PATH="${MAMBA_GITHOOK_BASE_PATH:-${MAMBA_GITHOOK_DIR}}"

. "${MAMBA_GITHOOK_BASE_PATH}/utils/logger.sh"

sh_cm_detect_shell() {
  ################################################
  # Detects the shell of the user. It will return
  # the name of the shell.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  parent=$(ps -o comm $PPID | tail -1)
  detected_shell="${SHELL##*/}"
  detected_shell="${detected_shell:-${parent#-}}"
  if [ ! -z "${detected_shell}" ]; then
    printf "%s\n" "${detected_shell}"
    return 0
  else
    log_error "Failed to detect the shell of the user"
    return 1
  fi
}

sh_cm_remove_file() {
  ################################################
  # Removes a file.
  #
  # Args:
  #   $1: Path to the file
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  file="$1"
  resp=$(rm "${file}" 2>&1) || {
    log_error "Failed to remove" "'${file}'." "STDERR: ${resp}"
    return 1
  }
  log_info "Removed" "'${file}'"
  return 0
}

sh_cm_remove_dir() {
  ################################################
  # Removes a directory.
  #
  # Args:
  #   $1: Path to the directory
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  dir="$1"
  resp=$(rm -r "${dir}" 2>&1) || {
    log_error "Failed to remove" "'${dir}'." "STDERR: ${resp}"
    return 1
  }
  log_info "Removed" "'${dir}'"
  return 0
}

sh_cm_backup_file() {
  ###############################################
  # Backs up the user's file into a backup file.
  #
  # Args:
  #   $1: File to back up
  #   $2: Backup file path (default: Same as file)
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  original_file="$1"
  backup_file_name="$(basename "${original_file}")"
  backup_file_path="${2:-"${original_file}"}"
  backup_timestamp="$(date +%Y-%m-%d-%H_%M_%S)"
  backup_file_path="${backup_file_path%/*}"   # Remove the file name from the path
  backup_file_path="${backup_file_path:-"."}" # If the path is empty, set it to current directory
  backup_file="${backup_file_path}/${backup_file_name}.${backup_timestamp}.bak"
  resp=$(cp "${original_file}" "${backup_file}" 2>&1) || {
    log_error "Failed to back up" "'${original_file}'" "to" "'${backup_file}'." "STDERR: ${resp}"
    return 1
  }
  log_info "Backed up" "'${original_file}'" "to" "'${backup_file}'"
  return 0
}

sh_cm_is_file_exist() {
  ################################################
  # Checks if a file exists.
  #
  # Args:
  #   $1: Path to the file
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  file="$1"
  if [ -f "${file}" ]; then
    log_debug "File" "'${file}'" "exists"
    return 0
  else
    log_warning "File" "'${file}'" "does not exist"
    return 1
  fi
}

sh_cm_is_dir_exist() {
  ################################################
  # Checks if a directory exists.
  #
  # Args:
  #   $1: Path to the directory
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  dir="$1"
  if [ -d "${dir}" ]; then
    log_debug "Directory" "'${dir}'" "exists"
    return 0
  else
    log_warning "Directory" "'${dir}'" "does not exist"
    return 1
  fi
}

sh_cm_mkdir() {
  ################################################
  # Creates a directory.
  #
  # Args:
  #   $1: Path to the directory
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  dir="$1"
  resp=$(mkdir -p "${dir}" 2>&1) || {
    log_error "Failed to create the directory" "'${dir}'." "STDERR: ${resp}"
    return 1
  }
  log_info "Created the directory" "'${dir}'"
  return 0
}

sh_cm_get_kernel_name() {
  ################################################
  # Gets the kernel name.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  kernel_name=$(uname -s 2>&1) || {
    log_error "Failed to get the kernel name." "STDERR: ${kernel_name}"
    return 1
  }
  printf "${kernel_name}\n"
  return 0
}

sh_cm_get_machine_hardware_name() {
  ################################################
  # Gets machine hardware name.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  architecture=$(uname -m 2>&1) || {
    log_error "Failed to get the architecture." "STDERR: ${architecture}"
    return 1
  }
  printf "${architecture}\n"
  return 0
}
