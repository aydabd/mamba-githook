#!/bin/sh
set -e

export DEBEMAIL="ayd.abd@gmail.com"
export DEBFULLNAME="Aydin.A"

# Install dependencies
apt-get update && apt-get install -y \
    build-essential \
    devscripts \
    debhelper \
    git \
    wget \
    curl

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

# Remove the package and its configuration files
dpkg -P mamba-githook-1.0

# Remove the package and its configuration files and uninstalled dependencies
apt-get purge mamba-githook-1.0

# Remove the package and its configuration files and all dependencies
apt-get remove --purge mamba-githook-1.0

# Remove the package and its configuration files and all dependencies and unused packages
apt-get autoremove --purge mamba-githook-1.0
