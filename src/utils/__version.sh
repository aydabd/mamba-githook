#############################################
# Update this file when release a new version
#############################################
set_semantic_version() {
  major=$1
  minor=$2
  patch=$3
  if [ -z "${major}" ] || [ -z "${minor}" ] || [ -z "${patch}" ]; then
    printf "Failed to set the semantic version.\n"
    return 1
  fi
  export MAMBA_GITHOOK_VERSION="${major}.${minor}.${patch}"
  return 0
}

get_version() {
  if [ -z "${MAMBA_GITHOOK_VERSION}" ]; then
    printf "Failed to get the version.\n"
    return 1
  fi
  printf "%s\n" "${MAMBA_GITHOOK_VERSION}"
  return 0
}

# Update the version for every release
set_semantic_version 1 0 0
