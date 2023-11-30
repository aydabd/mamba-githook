##################################################################################
# Title: logger.sh
# Description: This script contains functions for logging.
#
# Author: Aydin Abdi
#
# Usage:
#   'source logger.sh' or '. logger.sh'
#   log_info "This is an info message." "STDERR: This is an error message."
##################################################################################
set -e

# ANSI color code for the log levels(ex. WARNING logs are yellow)
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define the log levels
LOG_LEVELS="DEBUG INFO WARNING ERROR"

__message_format() {
  ########################################################
  # Formats the message.
  #
  # Args:
  #   $1: log_level
  #   $2: script name
  #   $3: all the other arguments
  ########################################################
  log_level="$1"
  script_name="$2"
  shift 2
  msg="$*"

  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  printf "%s" "${timestamp}-[${log_level}](${script_name}): ${msg}"
}

__print_log() {
  ########################################################
  # Prints the message in the given color if the terminal
  # supports color, otherwise prints the message without
  # color.
  #
  # Args:
  #   $1: log_level
  #   $2: color
  #   $3: script name
  #   $4: all the other arguments
  ########################################################
  log_level="$1"
  color="$2"
  script_name="$3"
  shift 3
  msg="$*"

  if __is_terminal_supports_color; then
    printf "%b\n" "${color}$(__message_format "${log_level}" "${script_name}" "${msg}")${NC}"
  else
    printf "%s\n" "$(__message_format "${log_level}" "${script_name}" "${msg}")"
  fi
}

__is_terminal_supports_color() {
  ########################################################
  # Checks if the terminal supports color.
  #
  # Returns:
  #   0 if the terminal supports color, 1 otherwise.
  ########################################################
  test -t 1 && test -n "${TERM}" && test "${TERM}" != "dumb"
  test "$(tput colors)" -ge 8 2>/dev/null || return 1
}

__check_log_level() {
  ########################################################
  # Checks if the log level is valid.
  #
  # Args:
  #   $1: log_level
  #
  # Returns:
  #   0 if the log level is valid, 1 otherwise.
  ########################################################
  log_level="$1"
  printf "%s" "${LOG_LEVELS}" | grep --quiet --word-regexp "${log_level}"
}

__main_logger() {
  #############################################################################
  # Logs the message with the given log level.
  #
  # Args:
  #   $1: The log level (e.g. INFO, ERROR, WARNING, DEBUG)
  #   $2: color name, default is NC (No Color)
  #   $3: The script name
  #   $4: The message to log
  #
  # Example:
  #   __logger INFO NC "$0" "This is an info message."
  #   output:
  #     '2021-03-21 15:30:00-[INFO](logger.sh): This is an info message.'
  #   __logger ERROR RED "$0" "This is an error message." "ERR"
  #   output:
  #     '2021-03-21 15:30:00-[ERROR](logger.sh): This is an error message. ERR'
  #############################################################################
  log_level="$1"
  color="${2:-${NC}}" # Default color is NC
  script_name="$3"
  shift 3
  msg="$*" # All the other arguments

  # Check log level exists
  __check_log_level "${log_level}" || {
    __print_log "ERROR" "${RED}" "${script_name}" "Invalid log level: ${log_level}"
    return 1
  }

  __print_log "${log_level}" "${color}" "${script_name}" "${msg}"
}

log_info() {
  #######################################################################
  # Logs an info message.
  #
  # Args:
  #   $1: The script name
  #   $2: The message to log
  #
  # Example:
  #   log_info "$0" "This is an info message."
  #   output:
  #     '2021-03-21 15:30:00-[INFO](logger.sh): This is an info message.'
  #######################################################################
  __main_logger INFO "${NC}" "$0" "$@" >&1 # stdout
}

log_error() {
  #########################################################################
  # Logs an error message.
  #
  # Args:
  #   $1: The script name
  #   $2: The message to log
  #
  # Example:
  #   log_error "$0" "This is an error message."
  #   output:
  #     '2021-03-21 15:30:00-[ERROR](logger.sh): This is an error message.'
  #########################################################################
  __main_logger ERROR "${RED}" "$0" "$@" >&2 # stderr
}

log_warning() {
  ############################################################################
  # Logs a warning message.
  #
  # Args:
  #   $1: The script name
  #   $2: The message to log
  #
  # Example:
  #   log_warning "$0" "This is a warning message."
  #   output:
  #     '2021-03-21 15:30:00-[WARNING](logger.sh): This is a warning message.'
  ############################################################################
  __main_logger WARNING "${YELLOW}" "$0" "$@" >&2 # stderr
}

log_debug() {
  #######################################################################
  # Logs a debug message.
  #
  # The debug logs are streamed to stderr if the
  # 'MAMBA_GITHOOK_VERBOSE' or 'MAMBA_GITHOOK_VERY_VERBOSE' environment
  # variables are set to true, otherwise the debug logs are streamed to
  # /dev/null.
  #
  # Args:
  #   $1: The script name
  #   $2: The message to log
  #
  # Example:
  #   log_debug "$0" "This is a debug message."
  #   output:
  #     '2021-03-21 15:30:00-[DEBUG](logger.sh): This is a debug message.'q
  ########################################################################
  verbose="${MAMBA_GITHOOK_VERBOSE:-false}"
  very_verbose="${MAMBA_GITHOOK_VERY_VERBOSE:-false}"
  # Stream debug logs if verbose is true otherwise stream to /dev/null
  test "${verbose:-very_verbose}" = "true" && __main_logger DEBUG "${BLUE}" "$0" "$@" >&2 || return 0
}
