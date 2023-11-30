#!/bin/sh
set -e

export DEBEMAIL="ayd.abd@gmail.com"
export DEBFULLNAME="Aydin Abdi"

# Install dependencies
apt-get update && apt-get install -y \
  build-essential \
  devscripts \
  debhelper \
  git \
  wget \
  curl \
  && apt-get clean\
  && rm -rf /var/lib/apt/lists/*
  && apt-get autoremove -y \
  && apt-get autoclean -y

# Clean the package will run dh_clean
fakeroot dh_clean

# Build the package
fakeroot dpkg-buildpackage --unsigned-source --unsigned-changes

# run lintian
lintian -v --fail-on warning ../*.changes

# Install the package
fakeroot dpkg -i mamba-githook-1.0.deb
# unmet dependencies installs
fakeroot apt-get -f install

# Remove the package
dpkg -r mamba-githook-1.0
or
apt-get remove mamba-githook-1.0

# Remove the package and its configuration files
dpkg -P mamba-githook-1.0
or
apt-get purge mamba-githook-1.0

# Remove the package and its configuration files and dependencies
dpkg -P --auto-deconfigure mamba-githook-1.0
or
apt-get purge --auto-remove mamba-githook-1.0

# force remove the package
dpkg --remove --force-remove-reinstreq mamba-githook-1.0
or
apt-get --fix-broken install

# create gpg key
gpg --full-generate-key

# list gpg keys
gpg --list-secret-keys --keyid-format LONG
gpg --fingerprint

# create debian changelog file if not exists with 'dch' tool
dch --create --package mamba-githook --newversion v1.0.0 -D stable "Initial release"

# update debian changelog file with 'dch'
dch --package mamba-githook --newversion v1.0.0 -D stable "Initial release"

# Release process
# 1. Update the version in the changelog
# 2. Commit the changes
# 3. Tag the commit
# 4. Push the changes
# 5. Create a release on github
# 6. Upload the package to github

# use debuild to build the package
debuild -- clean

# the package will be signed if you have a gpg key
debuild

# build the package without lintian check and without signing
debuild --no-lintian -us -uc -b --post-clean
