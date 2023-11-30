#########################################################
# Title: git_common.sh
# Description: This script contains common git functions.
# Public method names starts with 'git_cm_' prefix.
#
# Author: Aydin Abdi
#
# Usage:
#   'source git_common.sh' or '. git_common.sh'
#   git_cm_is_repo
#   git_cm_get_repo_root
#########################################################
set -e

# Use MAMBA_GITHOOK_BASE_PATH to override the base path of mamba-githook
MAMBA_GITHOOK_BASE_PATH="${MAMBA_GITHOOK_BASE_PATH:-"/usr/share/mamba-githook"}"

. "${MAMBA_GITHOOK_BASE_PATH}/utils/logger.sh"

git_cm_get_repo_root() {
  #################################################
  # Gets the current git repository root.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  #   The git repository root is printed to stdout.
  #################################################
  git_repo_root=$(git rev-parse --show-toplevel 2>&1) || {
    log_error "Failed to get the git repository root." "STDERR: ${git_repo_root}"
    return 1
  }
  printf "${git_repo_root}"
  return 0
}

git_cm_is_repo() {
  ################################################
  # Checks if the current directory is a git repo.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  resp=$(git_cm_get_repo_root 2>/dev/null) || {
    log_error "The current directory '$(pwd)' is not a git repository."
    return 1
  }
  return 0
}

git_cm_get_repo_name() {
  #################################################
  # Gets the current git repository name.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  #   The git repository name is printed to stdout.
  #################################################
  git_repo_root=$(git_cm_get_repo_root) || { return 1; }
  git_repo_name=$(basename "${git_repo_root}")
  printf "${git_repo_name}"
  return 0
}

git_cm_config_cmd() {
  ################################################
  # Runs a git config command.
  #
  # Args:
  #   $@: Git config args
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  git_config_args="$@"
  resp=$(git config $git_config_args 2>&1) || {
    log_error "Failed to run git config" "${git_config_args} command" "STDERR: ${resp}"
    return 1
  }
  log_info "git config" "${git_config_args} command is successful"
  return 0
}

git_cm_config_set_core_hookspath() {
  ################################################
  # Sets the core.hooksPath git config.
  #
  # Args:
  #   $1: Scope of the git config (e.g. --local)
  #   $2: Path to the hooks directory
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  scope="$1"
  hooks_dir="$2"
  case "${scope}" in
  --local | --global | --system)
    git_cm_config_cmd "${scope}" core.hooksPath "${hooks_dir}"
    ;;
  *)
    log_error "Invalid scope: ${scope}."
    return 1
    ;;
  esac
}

git_cm_config_unset_core_hookspath() {
  ################################################
  # Unsets the core.hooksPath git config.
  #
  # Args:
  #   $1: Scope of the git config (e.g. --local)
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  scope="$1"
  case "${scope}" in
  --local | --global | --system)
    git_cm_config_cmd "${scope}" --unset core.hooksPath
    ;;
  *)
    log_error "Invalid scope: ${scope}."
    return 1
    ;;
  esac
}

git_cm_config_get_core_hookspath() {
  #######################################################
  # Gets the core.hooksPath git config.
  #
  # Args:
  #   $1: Scope of the git config (e.g. local, global)
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  #   The core.hooksPath git config is printed to stdout.
  #######################################################
  scope="$1"
  case "${scope}" in
  --local | --global | --system)
    git_cm_config_cmd "${scope}" --get core.hooksPath
    ;;
  *)
    log_error "Invalid scope: ${scope}."
    return 1
    ;;
  esac
}
