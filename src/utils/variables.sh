##############################################################################
# Title: variables.sh
# Description: This script contains variables used by 'mamba-githook'.
# Author: Aydin Abdi
#
# Usage:
# source the script and use the variables:
#   >>> . variables.sh && echo $USER
#
# Note: The default values can be changed by setting the environment variables.
#       For example, to change the default value of the 'USER' variable,
#       set the 'USER' environment variable:
#       >>> export USER="new_user"
#       >>> . variables.sh && echo $USER
#       new_user
##############################################################################
MAMBA_GITHOOK="mamba-githook"
MAMBA_GITHOOK_DIR="${MAMBA_GITHOOK_DIR:-"/usr/share/${MAMBA_GITHOOK}"}"
MAMBA_GITHOOK_HOOKS_DIR="${MAMBA_GITHOOK_DIR}/hooks"
MAMBA_GITHOOK_BACKUP_DIR="${MAMBA_GITHOOK_DIR}/backup"
GIT_CONFIG_CORE_HOOKSPATH_BACKUP="${MAMBA_GITHOOK_BACKUP_DIR}/core.hookpath.config"
GIT_CONFIG_CORE_HOOKSPATH="core.hooksPath"

MAMBA_GITHOOK_MICROMAMBA_PREFIX="${MAMBA_GITHOOK_MICROMAMBA_PREFIX:-"${HOME}/micromamba"}"
MAMBA_GITHOOK_MICROMAMBA_ENV="${MAMBA_GITHOOK_MICROMAMBA_ENV:-${MAMBA_GITHOOK}}"
MAMBA_GITHOOK_MICROMAMBA_OPTIONS="--yes --quiet"

MICROMAMBA_CMD="micromamba"
MICROMAMBA_BIN_FOLDER="${MICROMAMBA_BIN_FOLDER:-"${HOME}/.local/bin"}"
MICROMAMBA_EXE="${MICROMAMBA_BIN_FOLDER}/${MICROMAMBA_CMD}"
MAMBA_EXE="${MICROMAMBA_EXE}"
MAMBA_ROOT_PREFIX="${MAMBA_GITHOOK_MICROMAMBA_PREFIX}"
