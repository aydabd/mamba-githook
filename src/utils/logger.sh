##################################################################################
# Title: logger.sh
# Description: This script contains functions for logging.
# Author: Aydin Abdi
#
# Usage:
#   'source logger.sh' or '. logger.sh'
#   log_info "This is an info message."
#
# Note: The log file path can be set by setting the LOG_FILE environment variable.
#       If the LOG_FILE environment variable is not set, the default log dir path
#       is /home/<user>/mamba-githook/logs/
##################################################################################

set -e

# Define the log levels
LOG_LEVELS="DEBUG INFO WARNING ERROR CRITICAL"
MAMBA_GITHOOK_LOG_DIR="${HOME}/mamba-githook/logs"

__log() {
  ########################################################
  # Logs a message to the log file.
  #
  # Args:
  #   $1: The log level (e.g. INFO, ERROR, WARNING, DEBUG)
  #   $2: The message to log
  ########################################################
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  log_level="${1}"
  shift
  msg="$*"

  # Check if the log level is valid
  if ! printf "%s" "${LOG_LEVELS}" | grep -q "${log_level}"; then
    printf "${timestamp}-[ERROR]: Invalid log level: %s\n" "${log_level}" &
    >2
    return 1
  fi
  # log error and critical messages to stderr
  if [ "${log_level}" = "ERROR" ] || [ "${log_level}" = "CRITICAL" ]; then
    printf "${timestamp}-[${log_level}]: ${msg}\n" &
    >2
  fi
  # log to file and stdout
  file_timestamp=$(date '+%Y-%m-%d')
  printf "${timestamp}-[$log_level]: ${msg}\n" |
    tee -a "${LOG_FILE:-$MAMBA_GITHOOK_LOG_DIR/mamba_githook_$file_timestamp.log}"
}

log_info() {
  __log INFO "$@"
}

log_error() {
  __log ERROR "$@"
}

log_warning() {
  __log WARNING "$@"
}

log_debug() {
  __log DEBUG "$@"
}

log_critical() {
  __log CRITICAL "$@"
}
