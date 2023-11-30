######################################################################
# Title: Changelog functions
# Description: This script contains functions to handle the changelog.
#
# Author: Aydin Abdi
######################################################################

# Function to check if the current commit is tagged
is_current_commit_tagged() {
    get_current_commit_tag >/dev/null || return 1
}

# Function to get tag of the current commit
get_current_commit_tag() {
    git describe --tags --exact-match 2>/dev/null
}

# Function to get the commit message of a commit hash
get_commit_message() {
    commit_hash=$1
    git show -s --pretty=format:"%h - %s%n" "${commit_hash}"
}

# Get commit messages between current two tags
get_commit_hashes_until_current_tag() {
    # Try to get the last tag before the current HEAD
    last_tag=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null)

    # If there is no previous tag, get all commit hashes from the beginning
    if [ -z "$last_tag" ]; then
        git log --pretty=format:"%h" | awk '{print $1}' || {
            printf "No commit hashes found.\n"
            return 1
        }
    else
        # Get commit hashes from the last tag to the current HEAD
        git log --pretty=format:"%h" ${last_tag}..HEAD | awk '{print $1}' || {
            printf "No commit hashes found.\n"
            return 1
        }
    fi
}

__is_new_version() {
    version=$1
    current_tag=$(get_current_commit_tag)
    if [ "${version}" = "${current_tag}" ]; then
        printf "The version is already released.\n"
        return 1
    fi
}

# Function to create a tag
create_tag() {
    version=$1
    git tag -a "$version" -m "Release version $version"
}

# Function to create the changelog file if it does not exist
__create_changelog() {
    version="$1"
    package_name="$2"
    release_message="$3"

    resp=$(dch --create -M -v "${version}" --package "${package_name}" -D unstable "${release_message}" 2>&1) || {
        printf "Changelog already exists.\n" "STDERR: ${resp}"
        return 0
    }
}

# Function to create a new changelog entry for a new version
__create_new_changelog_entry() {
    version="$1"
    package_name="$2"
    release_message="$3"

    resp=$(dch -M -v "${version}" -D unstable "${release_message}" 2>&1) || {
        printf "Failed to create a new changelog entry.\n" "STDERR: ${resp}"
        return 1
    }
}

# Function to update the changelog with the commit messages
__update_changelog() {
    commit_hashes="$1"

    for commit_hash in $(echo "${commit_hashes}"); do
        commit_message=$(get_commit_message "${commit_hash}" 2>&1)
        dch -a "* ${commit_message}" || {
            printf "Failed to append the commit message to the changelog.\n"
            return 1
        }
    done

    printf "#############################################################\n"
    printf "#### Check debian/changelog file and update it if needed.####\n"
    printf "#############################################################\n"
}

# Function to release a new version
changelog_release() {
    dch --release "" || {
        printf "Failed to finalize the changelog entry.\n"
        return 1
    }
}

# Function to commit the changelog
__commit_changelog() {
    version=$1
    git add debian/changelog
    git commit -m "Update changelog for version ${version}"
}

# Function to handle the changelog
handle_changelog() {
    version="$1"
    package_name="${2:-mamba-githook}"
    release_message="${4:-Release version ${version}}"
    commit_hashes="${3:-$(get_commit_hashes_until_current_tag)}"
    release_flag="${5:-false}"
    is_current_commit_tagged

    if [ ! -f "debian/changelog" ]; then
        resp_create=$(__create_changelog "${version}" "${package_name}" "${release_message}" 2>&1) || {
            printf "STDERR: ${resp_create}\n"
            return 1
        }
    else
        resp_entry=$(__create_new_changelog_entry "${version}" "${package_name}" "${release_message}" 2>&1) || {
            printf "STDERR: ${resp_entry}\n"
            return 1
        }
    fi

    resp_update=$(__update_changelog "${commit_hashes}" 2>&1) || {
        printf "STDERR: ${resp_update}\n"
        return 1
    }

    if [ "${release_flag}" = "true" ]; then
        changelog_release || {
            printf "Failed to finalize the changelog entry.\n"
            return 1
        }
    fi

    return 0
}

commit_changelog() {
    current_tag=$(get_current_commit_tag)
    if [ -z "${current_tag}" ]; then
        echo "No tag found for the current commit."
        return 1
    fi

    __commit_changelog "${current_tag}"
}
