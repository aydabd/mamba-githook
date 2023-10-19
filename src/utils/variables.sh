##############################################################################
# Title: variables.sh
# Description: This script contains variables used by 'mamba-githook'.
# Author: Aydin Abdi
#
# Usage:
# source the script and use the variables:
#   >>> . variables.sh && echo $ORIG_USER
##############################################################################

ORIG_USER="${SUDO_USER:-$USER}"
HOME="/home/${ORIG_USER}"
BIN_FOLDER="${HOME}/.local/bin"
MICROMAMBA_EXE="${BIN_FOLDER}/micromamba"
MICROMAMBA_CMD="micromamba"
DEFAULT_MICROMAMBA_PREFIX="${HOME}/micromamba"
BASHRC="${HOME}/.bashrc"
ZSHRC="${HOME}/.zshrc"
XONSHRC="${HOME}/.xonshrc"
FISH_CONFIG="${HOME}/.config/fish/config.fish"
SHELL_RC_FILE=""
DEFAULT_CONDA_FORGE_YES="yes"

# initiate the micromamba environment by default into shell
# Set to no if you want to initiate the environment manually later
DEFAULT_INITIATE="no"

PREFIX_LOCATION="${PREFIX_LOCATION:-$DEFAULT_MICROMAMBA_PREFIX}"
MICROMAMA_CREATE_ENV_CMD="sudo -u ${ORIG_USER} ${MICROMAMBA_EXE} create"
MICROMAMBA_ENV_LIST_CMD="sudo -u ${ORIG_USER} ${MICROMAMBA_EXE} env list --json"
MICROMAMBA_LIST_CMD="sudo -u ${ORIG_USER} ${MICROMAMBA_EXE} list --json"
DEFAULT_GIT_HOOK_MICROMAMBA_ENV="mamba-githook"
DEFAULT_MICROMAMBA_CHANNEL="conda-forge"
DEFAULT_MICROMAMBA_OPTIONS="--yes --quiet"

MAMBA_GITHOOK_DIR="/usr/share/mamba-githook"
MAMBA_GITHOOK_HOOKS_PATH="${MAMBA_GITHOOK_DIR}/hooks"
MAMBA_GITHOOK_SCRIPTS="${MAMBA_GITHOOK_DIR}/scripts"
CONFIGURE_MICROMAMBA_SCRIPT="${MAMBA_GITHOOK_SCRIPTS}/configure_micromamba"
CORE_HOOKSPATH_OPTION="core.hooksPath"
INIT_TEMPLATEDIR_OPTION="init.templatedir"

DEFAULT_MICROMAMBA_ENV_NAME="mamba-githook"
DEFAULT_MICROMAMBA_ENV_PATH="${DEFAULT_MICROMAMBA_PREFIX}/envs/"
TEMPLATE_DIR="${MAMBA_GITHOOK_DIR}/templates/project_sample"
PRE_COMMIT_SAMPLE="pre-commit_sample"

# TODO: Move these last lines into the there script will use it otherwise it will fail
# if the user does not have a git repo
REPO_ROOT=$(git rev-parse --show-toplevel) || {
    echo "Could not find the git repository root"
    exit 1
}
LOCAL_GIT_HOOKS_DIR="${REPO_ROOT}/.githooks.d"
DEFAULT_ENV_YAML_FILE="${LOCAL_GIT_HOOKS_DIR}/environment_template.yml"
