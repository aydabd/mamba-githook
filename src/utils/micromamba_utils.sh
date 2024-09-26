################################################################
# Title: micromamba_utils.sh
# Description: This script contains common micromamba functions.
# Public method names starts with 'mcmamba_utils_' prefix.
# Private method names starts with '__' prefix.
#
# Author: Aydin Abdi
#
# Usage:
#   'source micromamba_utils.sh' or '. micromamba_utils.sh'
#   mcmamba_utils_install_micromamba
#   mcmamba_utils_uninstall_micromamba
################################################################
set -e

# Use MAMBA_GITHOOK_BASE_PATH to override the base path of mamba-githook
MAMBA_GITHOOK_BASE_PATH="${MAMBA_GITHOOK_BASE_PATH:-${MAMBA_GITHOOK_DIR}}"

. "${MAMBA_GITHOOK_BASE_PATH}/utils/variables.sh"
. "${MAMBA_GITHOOK_BASE_PATH}/utils/logger.sh"
. "${MAMBA_GITHOOK_BASE_PATH}/utils/shell_common.sh"

MICROMAMBA_SHELL_HOOK_CMD="shell hook"
MICROMAMBA_SHELL_INIT_CMD="shell init"
MICROMAMBA_SHELL_DEINIT_CMD="shell deinit"
MICROMAMBA_ENV_LIST_CMD="env list --json"

mcmamba_utils_is_micromamba_installed() {
  ##################################################
  # Checks if micromamba is installed in the system.
  #
  # Returns:
  #   0 if micromamba is installed, otherwise 1.
  ##################################################
  if [ ! -f "${MICROMAMBA_EXE}" ]; then
    log_error "Could not find micromamba executable" "'${MICROMAMBA_EXE}'"
    return 1
  fi

  log_debug "Micromamba is installed:" "'${MICROMAMBA_EXE}'"
  return 0
}

__is_micromamba_shell_init_supported() {
  ##########################################################
  # Checks if the detected shell is supported by command:
  # micromamba shell init <shel-typ>
  # Supported shells: (bash, fish, posix, xonsh, zsh)
  #
  # Args:
  #   $1: shell name
  #
  # Returns:
  #   0 if the detected shell is supported, otherwise 1.
  ##########################################################
  shell_name="$1"
  case "${shell_name}" in
  posix | bash | fish | xonsh | zsh)
    log_info "Micromamba supports" "'${shell_name}'"
    return 0
    ;;
  *)
    log_warning "Micromamba does not support" "'${shell_name}'"
    return 1
    ;;
  esac
}

__is_kernel_supported() {
  ##########################################################
  # Checks if the kernel is supported by micromamba.
  # Supported kernels: (Linux, Darwin, Windows)
  #
  # Args:
  #   $1: kernel name
  #
  # Returns:
  #   0 if the kernel is supported, otherwise 1.
  ##########################################################
  kernel_name="$1"
  case "${kernel_name}" in
  Linux | Darwin | *NT*)
    return 0
    ;;
  *)
    log_warning "Micromamba does not support" "'${kernel_name}'"
    return 1
    ;;
  esac
}

__convert_kernel_name() {
  #########################################################
  # Gets the converted kernel name based on the kernel name
  # and supported kernels by micromamba.
  # Supported kernels: (Linux, Darwin, Windows)
  #
  # Args:
  #   $1: kernel name
  #
  # Returns:
  #   returns the converted kernel name, otherwise empty.
  #########################################################
  kernel_name="$1"
  case "${kernel_name}" in
  Linux)
    printf "linux\n"
    ;;
  Darwin)
    printf "osx\n"
    ;;
  *NT*)
    printf "win\n"
    ;;
  *) # pass
    ;;
  esac
}

__convert_architecture() {
  #########################################################
  # Gets the converted architecture based on the architecture
  # and supported architectures by micromamba.
  # Supported architectures: (64)
  #
  # Args:
  #   $1: architecture/machine hardware name
  #
  # Returns:
  #   returns the converted architecture, otherwise 64.
  #########################################################
  architecture="$1"
  case "${architecture}" in
  aarch64 | ppc64le | arm64)
    printf "${architecture}\n"
    ;;
  *)
    printf "64\n"
    ;;
  esac
}

__is_platform_architecture_supported() {
  #################################################################
  # Checks if the platform and architecture is supported by
  # micromamba.
  # Supported platforms-arch: (linux-64, linux-aarch64,
  # linux-ppc64le, osx-64, osx-arm64, win-64)
  #
  # Args:
  #   $1: platform
  #   $2: architecture
  #
  # Returns:
  #   0 if the platform and architecture is supported, otherwise 1.
  #################################################################
  platform="$1"
  architecture="$2"
  case "${platform}-${architecture}" in
  linux-aarch64 | linux-ppc64le | linux-64 | osx-arm64 | osx-64 | win-64)
    log_info "Micromamba supports" "'${platform}-${architecture}'"
    return 0
    ;;
  *)
    log_warning "Micromamba does not support" "'${platform}-${architecture}'"
    return 1
    ;;
  esac
}

__get_micromamba_url_artifact() {
  ###########################################################
  # Gets the micromamba release url based on the platform and
  # architecture.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  #   The micromamba release url is printed to stdout.
  ###########################################################
  kernel_name=$(sh_cm_get_kernel_name) || { return 1; }
  resp=$(__is_kernel_supported "${kernel_name}" 2>/dev/null) || {
    return 1
  }
  platform=$(__convert_kernel_name "${kernel_name}")

  architecture=$(sh_cm_get_machine_hardware_name) || { return 1; }
  architecture=$(__convert_architecture "${architecture}")

  resp=$(__is_platform_architecture_supported "${platform}" "${architecture}" 2>/dev/null) || {
    return 1
  }
  printf "%s\n" "https://github.com/mamba-org/micromamba-releases/releases/latest/download/micromamba-${platform}-${architecture}"
  return 0
}

__download_micromamba_artifact() {
  ################################################
  # Downloads the micromamba artifact.
  #
  # Args:
  #   $1: bin folder path to download micromamba
  #   $2: micromamba release url
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  bin_folder="$1"
  release_url="$2"
  mkdir_resp=$(mkdir -p "${bin_folder}" 2>&1) || {
    log_error "Failed to create the directory" "'${bin_folder}'." "STDERR: ${mkdir_resp}"
    return 1
  }
  log_info "Downloading micromamba from" "'${release_url}'"
  if command -v curl >/dev/null; then
    curl_resp=$(curl -o "${bin_folder}/micromamba" -fsSL --compressed "${release_url}" 2>&1) || {
      log_error "Failed to download micromamba from" "'${release_url}'" "STDERR: ${curl_resp}"
      return 1
    }
  elif command -v wget >/dev/null; then
    wget_resp=$(wget -qO "${bin_folder}/micromamba" "'${release_url}'" 2>&1) || {
      log_error "Failed to download micromamba from" "'${release_url}'." "STDERR: ${wget_resp}"
      return 1
    }
  else
    log_error "Neither curl nor wget was found"
    return 1
  fi
  chmod_resp=$(chmod +x "${bin_folder}/micromamba" 2>&1) || {
    log_error "Failed to set executable permission on" "'${bin_folder}/micromamba'." "STDERR: ${chmod_resp}"
    return 1
  }
  log_info "Downloaded micromamba to" "'${bin_folder}/micromamba'"
  return 0
}

mcmamba_utils_run_micromamba_cmd() {
  ################################################
  # Wrapper function to run micromamba command.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mcmamba_utils_is_micromamba_installed
  if [ $# -eq 0 ]; then
    log_error "No arguments provided to micromamba command"
    return 1
  fi

  test "${MAMBA_GITHOOK_VERBOSE}" = "true" && cmd_option="--yes" || true
  test "${MAMBA_GITHOOK_VERY_VERBOSE}" = "true" && cmd_option="--yes -vv" || true
  cmd="${MICROMAMBA_EXE} ${cmd_option:-$MAMBA_GITHOOK_MICROMAMBA_OPTIONS} $@"
  resp=$($cmd 2>&1) || {
    log_error "Command '${cmd}' failed." "STDERR: ${resp}"
    return 1
  }
  if [ ! -z "${resp}" ]; then
    printf "%s\n" "${resp}"
  fi
  return 0
}

__configure_condarc() {
  ################################################
  # Configures the '.condarc' file.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mcmamba_utils_run_micromamba_cmd config append channels conda-forge || { return 1; }
  mcmamba_utils_run_micromamba_cmd config append channels nodefaults || { return 1; }
  mcmamba_utils_run_micromamba_cmd config set channel_priority strict || { return 1; }
  mcmamba_utils_run_micromamba_cmd config set always_yes true || { return 1; }
  log_info "Micromamba is configured to use conda-forge and nodefaults."
  return 0
}

__remove_conda_files() {
  ###########################
  # Removes micromamba files.
  ###########################
  failed=0
  # remove micromamba root prefix(all envs and pkgs)
  if sh_cm_is_dir_exist "${MAMBA_GITHOOK_MICROMAMBA_PREFIX}"; then
    sh_cm_remove_dir "${MAMBA_GITHOOK_MICROMAMBA_PREFIX}" || {
      failed=1
    }
  fi

  # remove conda config file
  if sh_cm_is_file_exist "${HOME}/.condarc"; then
    sh_cm_remove_file "${HOME}/.condarc" || {
      failed=1
    }
  fi

  # remove mamba config file
  if sh_cm_is_file_exist "${HOME}/.mambarc"; then
    sh_cm_remove_file "${HOME}/.mambarc" || {
      failed=1
    }
  fi

  # remove mamba cache files
  if sh_cm_is_dir_exist "${HOME}/.mamba"; then
    sh_cm_remove_dir "${HOME}/.mamba" || {
      failed=1
    }
  fi

  # remove conda cache files
  if sh_cm_is_dir_exist "${HOME}/.conda"; then
    sh_cm_remove_dir "${HOME}/.conda" || {
      failed=1
    }
  fi

  # remove micromamba binary
  if sh_cm_is_file_exist "${MICROMAMBA_EXE}"; then
    sh_cm_remove_file "${MICROMAMBA_EXE}" || {
      failed=1
    }
  fi

  if [ "${failed}" -eq 1 ]; then
    return 1
  fi
  return 0
}

#############################################################
# Use these functions for mamba-githook application commands.
#
# These make the code more readable and maintainable.
#############################################################

mcmamba_utils_install_micromamba() {
  ################################################
  # Installs micromamba and configures it.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  mcmamba_utils_is_micromamba_installed 2>/dev/null || {
    micromamba_release_url=$(__get_micromamba_url_artifact 2>/dev/null)
    __download_micromamba_artifact "${MICROMAMBA_BIN_FOLDER}" "${micromamba_release_url}"
  }
  __configure_condarc
  log_info "Micromamba is installed successfully"
  return 0
}

mcmamba_utils_uninstall_micromamba() {
  ################################################
  # Uninstalls micromamba and removes all files.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  deinit_resp=$(mcmamba_utils_micromamba_shell_deinit 2>&1) || {
    log_debug "STDOUT: ${deinit_resp}"
  }

  __remove_conda_files || { return 1; }

  # Unset the micromamba command
  hash_resp=$(hash -r "${MICROMAMBA_CMD}" 2>/dev/null) || {
    log_debug "micromamba command was not hashed"
  }
  log_info "Micromamba is uninstalled successfully"
  return 0
}

mcmamba_utils_micromamba_shell_hook_cmd() {
  ################################################
  # Creates a single string of shell hook command.
  #
  # Run this with 'eval' command to set the shell
  # hook command in the current shell.
  #
  # Args:
  #   $1: Shell type
  #   $2: Path to the mamba root prefix
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  shell_type="${1:-posix}"
  mamba_root_prefix="${2:-$MAMBA_ROOT_PREFIX}"

  __is_micromamba_shell_init_supported "${shell_type}" >/dev/null || {
    return 1
  }

  cmd="${MICROMAMBA_EXE} ${MICROMAMBA_SHELL_HOOK_CMD} --root-prefix ${mamba_root_prefix} -s ${shell_type}"
  $cmd
}

mcmamba_utils_micromamba_shell_init() {
  ################################################
  # Make micromamba command persistent in shell.
  #
  # 'micromamba' command will be available in the
  # current shell and all subshells. In this case
  # micromamba command is persistent.
  # check 'micromamba shell init --help' for
  # supported shells.
  #
  # Args:
  #   $1: Shell type
  #   $2: Path to the mamba root prefix
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  detected_shell=$(sh_cm_detect_shell)
  shell_type="${1:-$detected_shell}"
  mamba_root_prefix="${2:-$MAMBA_ROOT_PREFIX}"

  __is_micromamba_shell_init_supported "${shell_type}"
  mcmamba_utils_run_micromamba_cmd "${MICROMAMBA_SHELL_INIT_CMD}" -s "${shell_type}" \
    --root-prefix "${mamba_root_prefix}"
}

mcmamba_utils_micromamba_shell_deinit() {
  ################################################
  # Restores the shell rc file.
  #
  # Args:
  #    $1: Shell type
  #    $2: Path to the mamba root prefix
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  detected_shell=$(sh_cm_detect_shell)
  shell_type="${1:-$detected_shell}"
  mamba_root_prefix="${2:-$MAMBA_ROOT_PREFIX}"

  __is_micromamba_shell_init_supported "${shell_type}"
  mcmamba_utils_run_micromamba_cmd "${MICROMAMBA_SHELL_DEINIT_CMD}" -s "${shell_type}" \
    --root-prefix "${mamba_root_prefix}"
}

mcmamba_utils_micromamba_env_exists() {
  ######################################################
  # Checks if a specified micromamba environment exists.
  #
  # Args:
  #   $1: Name of the micromamba environment
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ######################################################
  MAMBA_GITHOOK_MICROMAMBA_PREFIX="${MAMBA_GITHOOK_MICROMAMBA_PREFIX:-"${HOME}/micromamba"}"
  env_name="$1"
  expected_response="\"${MAMBA_GITHOOK_MICROMAMBA_PREFIX}/envs/${env_name}\""

  # Check if the specified micromamba environment exists in the output
  if mcmamba_utils_run_micromamba_cmd "${MICROMAMBA_ENV_LIST_CMD}" |
    grep -q "${expected_response}"; then
    return 0
  else
    log_warning "Could not find micromamba environment" "'${env_name}'"
    return 1
  fi
}

mcmamba_utils_micromamba_create() {
  #################################################
  # Creates a micromamba environment.
  #
  # Args:
  #   $@: Arguments for 'micromamba create'
  #      see micromamba documentation for more info
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  #################################################
  # if no argument show the help
  if [ $# -eq 0 ]; then
    mcmamba_utils_run_micromamba_cmd create --help # print usage help
  else
    mcmamba_utils_run_micromamba_cmd create "$@"
  fi
}

mcmamba_utils_micromamba_run_cmd() {
  ################################################
  # Call 'micromamba run' command.
  #
  # Args:
  #   $@: Arguments for 'micromamba run'
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  if [ $# -eq 0 ]; then
    mcmamba_utils_run_micromamba_cmd run --help # print usage help
  else
    mcmamba_utils_run_micromamba_cmd run "$@"
  fi
}
