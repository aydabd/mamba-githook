setup_test__get_micromamba_url_artifact() {
  # mock external 'sh_cm_get_kernel_name' response
  sh_cm_get_kernel_name() { printf "Linux"; }

  # mock external '__is_kernel_supported' response
  __is_kernel_supported() { return 0; }

  # mock external '__convert_kernel_name' response
  __convert_kernel_name() { printf "linux"; }

  # mock external 'sh_cm_get_machine_hardware_name' response
  sh_cm_get_machine_hardware_name() { printf "64"; }

  # mock external '__convert_architecture' response
  __convert_architecture() { printf "64"; }

  # mock external '__is_platform_architecture_supported' response
  __is_platform_architecture_supported() { return 0; }
}

setup_test__download_micromamba_artifact_with_curl() {
  mkdir() { return 0; }
  # Just mock the curl command to return 0 otherwise fail the command
  command() {
    case "$1" in
    -v)
      case "$2" in
      curl)
        return 0
        ;;
      *)
        return 1
        ;;
      esac
      ;;
    *)
      return 1
      ;;
    esac
    return 1
  }
  curl() { return 0; }
  chmod() { return 0; }
}

setup_test__download_micromamba_artifact_with_wget() {
  mkdir() { return 0; }
  # Just mock the wget command to return 0 otherwise it will fail
  command() {
    case "$1" in
    -v)
      case "$2" in
      wget)
        return 0
        ;;
      *)
        return 1
        ;;
      esac
      ;;
    *)
      return 1
      ;;
    esac
    return 1
  }
  wget() { return 0; }
  chmod() { return 0; }
}

setup_test__download_micromamba_artifact_command_not_found() {
  mkdir() { return 0; }
  # Mock the command command to return 1
  command() {
    case "$1" in
    -v)
      case "$2" in
      curl)
        return 1
        ;;
      wget)
        return 1
        ;;
      *)
        return 0
        ;;
      esac
      ;;
    *)
      return 0
      ;;
    esac
    return 0
  }
}

mock_rm_shell_cmd_passes() {
  # Mock rm to pass
  rm() {
    return 0
  }
}

mock_rm_shell_cmd_fails() {
  # Mock rmto fail
  rm() {
    return 1
  }
}

mock_cp_shell_cmd_passes() {
  cp() {
    return 0
  }
}

mock_cp_shell_cmd_fails() {
  cp() {
    return 1
  }
}

mock_mkdir_shell_cmd_passes() {
  mkdir() {
    return 0
  }
}

mock_mkdir_shell_cmd_fails() {
  mkdir() {
    return 1
  }
}

mock_uname_shell_cmd_passes() {
  uname() {
    case "$1" in
    -s)
      printf "Linux\n"
      return 0
      ;;
    -m)
      printf "x86_64\n"
      return 0
      ;;
    *)
      printf "N/A\n"
      return 1
      ;;
    esac
  }
}

mock_uname_shell_cmd_fails() {
  uname() {
    case "$1" in
    -s)
      printf "FreeBSD\n"
      return 1
      ;;
    -m)
      printf "x86_32\n"
      return 1
      ;;
    *)
      printf "FreeBSD\n"
      return 1
      ;;
    esac
    return 1
  }
}

rm_temp_dir() {
  ################################################
  # Remove the temporary test directory.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  test_dir="$1"
  rm -r "${test_dir}"
  if [ $? -ne 0 ]; then
    printf "Failed to remove the temporary test directory.\n"
    return 1
  fi
}

create_temp_test_directory() {
  ################################################
  # create a temporary test directory.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  # Create a random test directory(like: unittests_mamba_githook_<random-ID>)
  mktemp -d -t test_mamba_githook_XXXXXXXXXX
  if [ $? -ne 0 ]; then
    printf "Failed to create a random test directory.\n"
    return 1
  fi
}

change_to_test_dir() {
  ################################################
  # Go to the test directory.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  test_dir="$1"
  cd "${test_dir}" || {
    printf "Failed to go to the test directory.\n"
    return 1
  }
}

git_init_main() {
  ##################################
  # Setups the local git repository.
  ##################################
  dir_init="${1:-"."}"
  git init -b main "${dir_init}"
}

git_config_user() {
  ######################################
  # Configures the local git repository.
  ######################################
  scope="${1:-"--local"}"
  git config "${scope}" user.name "test-mamba-githook"
  git config "${scope}" user.email "noreply@test-mamba-githook"
}

git_config_get_core_hookspath() {
  ########################################################
  # Gets the core.hooksPath from the local git repository.
  ########################################################
  scope="${1:-"--local"}"
  git config "${scope}" core.hooksPath
}

git_config_global_unset_core_hookspath() {
  ###########################################################
  # Unsets the core.hooksPath from the global git repository.
  ###########################################################
  git config --global --unset core.hooksPath
}

check_micromamba_installed() {
  ################################################
  # Checks if micromamba is installed.
  #
  # Returns:
  #   0 if the command is successful, 1 otherwise.
  ################################################
  test -f "${HOME}/.local/bin/micromamba"
}
