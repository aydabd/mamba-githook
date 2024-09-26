####################################################################
# Title: run_hooks.sh
# Description: Runs the git hooks in the .githooks.d directory.
# This pre-commit hooks configured based on 'mamba-githook' package.
# Private method names starts with '__' prefix.
#
# Author: Aydin Abdi
#
# Usage:
#   'source run_hooks.sh' or '. run_hooks.sh'
#   hooks_runner <hook_type> <path_to_githooks_dir>
#
# Note: The hook name should be in the format of
#       pre-commit.priority.hook_name.
#       Priority is optional. Priority is used to
#       determine the order of the hooks. Lower
#       values have higher priority.
#
# Example:
#   hooks_runner pre-commit .githooks.d
#   # Output: Runs the pre-commit hooks in the .githooks.d directory.
#   hooks_runner pre-push .githooks.d
#   # Output: Runs the pre-push hooks in the .githooks.d directory.
#####################################################################
set -e

# Use MAMBA_GITHOOK_BASE_PATH to override the base path of mamba-githook
MAMBA_GITHOOK_BASE_PATH="${MAMBA_GITHOOK_BASE_PATH:-${MAMBA_GITHOOK_DIR}}"

. "${MAMBA_GITHOOK_BASE_PATH}/utils/variables.sh"
. "${MAMBA_GITHOOK_BASE_PATH}/utils/logger.sh"
. "${MAMBA_GITHOOK_BASE_PATH}/utils/shell_common.sh"

__get_hook_type() {
  #################################################
  # Gets the type of the hook. The hook type is
  # the first part of the hook name.
  #
  # The hook name should be in the format of
  # pre-commit.priority.hook_name.
  # Priority is optional. Priority is used to
  # determine the order of the hooks. Lower
  # values have higher priority.
  #
  # Example:
  #   __get_hook_type pre-commit.40.jira
  #   # Output: pre-commit
  #   __get_hook_type pre-push.jira
  #   # Output: pre-push
  #
  # Args:
  #   $1: Hook script name
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  #################################################
  hook_name="$1"
  hook_type=$(echo "${hook_name}" | cut -d'.' -f1) || {
    log_warning "Could not find the type of the hook" "${hook_name}"
    log_info "Hook name should be in the format of" "pre-commit.priority.hook_name"
    return 1
  }
  printf "${hook_type}\n"
}

get_available_hooks_types() {
  ###################################################
  # Gets the available hook types from git help hooks
  # command.
  #
  # Returns:
  #   The available hook types.
  #   0 if the command is successful, 1 otherwise.
  ###################################################
  git help hooks | grep -E '^[[:blank:]]{3}[a-zA-Z0-9-]+' | cut -d' ' -f4 | sort | uniq
}

is_git_hook_type_valid() {
  ################################################
  # Validates the hook type.
  #
  # The hook type should be one of the git hook
  # types.
  # See: https://git-scm.com/docs/githooks
  #
  # Args:
  #   $1: Hook type
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  hook_type="$1"
  case "${hook_type}" in
  applypatch-msg* | commit-msg* | fsmonitor-watchman* | p4-changelist* | \
    post-applypatch* | post-checkout* | post-commit* | post-index-change* | \
    post-merge* | post-receive* | post-rewrite* | post-update* | pre-applypatch* | \
    pre-auto-gc* | pre-commit* | pre-merge-commit* | pre-push* | pre-rebase* | \
    pre-receive* | prepare-commit-msg* | push-to-checkout* | sendemail-validate* | \
    update*)
    log_debug "The hook name" "'${hook_type}'" "is a git hook name"
    return 0
    ;;
  *)
    test -z "${hook_type}" && {
      log_error "The hook name" "is empty"
      return 1
    }
    log_error "The hook name" "'${hook_type}'" "is not a git hook name"
    return 1
    ;;
  esac
}

hooks_runner() {
  #################################################
  # Runs the githooks in the .githooks.d directory
  # based on the hook type.
  #
  # After running all hooks, it will fail if any
  # of the hooks failed.
  #
  # Args:
  #   $1: Hook type
  #   $2: Path to the custom hooks directory inside
  #       the git repository.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  #################################################
  failed=0
  hook_type="$1"
  githooks_dir="$2"

  is_git_hook_type_valid "${hook_type}"

  # Check the hooks in the .githooks.d directory and run them
  # if they have correct hook type and are executable.
  test -z "${githooks_dir}" && {
    log_error "The path to the custom hooks directory is empty"
    return 1
  }
  sh_cm_is_dir_exist "${githooks_dir}"
  log_debug "Running the" "${hook_type}" "hooks in" "${githooks_dir}"
  for hook in "${githooks_dir}"/*; do
    log_debug "Checking" "${hook}"
    if [ -x "${hook}" ]; then
      hook_name=$(basename "${hook}")
      file_hook_type=$(__get_hook_type "${hook_name}")
      if [ "${file_hook_type}" = "${hook_type}" ]; then
        log_info "Running" "${hook_name}"
        "${hook}" || {
          log_warning "Failed to run" "${hook_name}"
          failed=1
        }
      fi
    fi
  done
  return "${failed}"
}
