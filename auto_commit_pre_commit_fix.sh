#!/bin/sh

failed=0
#SOURCE_BRANCH_NAME="${GITHUB_REF##*/}"

# Run pre-commit checks
pre-commit run --all-files

# If pre-commit failed and any files have been modified, commit and push changes and exit with error
if [ $? -ne 0 ] && [ -n "$(git status --porcelain)" ]; then
    git config --global user.name "github-actions[bot]"
    git config --global user.email "github-actions[bot]@users.noreply.github.com"
    git add -A
    git commit -m "[auto-commit] Fix pre-commit errors"
    git remote set-url origin https://x-access-token:${GITHUB_TOKEN}@github.com/aydabd/mamba-githook.git
    git fetch origin "${GIT_REF_BRANCH}"
    git rebase origin/"${GIT_REF_BRANCH}"
    git push origin HEAD:"${GIT_REF_BRANCH}"
    failed=1
fi

exit $failed
