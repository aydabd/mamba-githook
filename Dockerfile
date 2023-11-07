######################################################################################################################################
# Title: Dockerfile for running integration tests for the mamba-githook package
# Description: This Dockerfile sets up a Debian-based environment for building mamba-githook
#              and running integration tests for the mamba-githook package.
#
# Author: Aydin Abdi
#
# Examples of how to build and run the integration tests using Docker:
#
# To build the docker image, run the following command from the root of the repository:
# docker build -t mamba-githook-integration-tests -f tests/integration_tests/Dockerfile .
#
# To run the integration tests, run the following command from the root of the repository:
# docker run --rm -it -v $(pwd):/app mamba-githook-integration-tests
#
# To run the integration tests and save the test report to a file, run the following command from the root of the repository:
# docker run --rm -it -v $(pwd):/app mamba-githook-integration-tests > mamba_githook_integration_tests.xml
######################################################################################################################################

# Base Image for Building the mamba-githook Package
FROM debian:bookworm as builder

LABEL maintainer="Aydin Abdi" \
    description="Builder image for mamba-githook package" \
    version="1.0.0"

# Set up the environment
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Stockholm

# Set up the working directory
WORKDIR /app

# Install necessary packages
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    build-essential \
    devscripts \
    debhelper \
    # Clean up in the same layer to keep the image size down
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# Copy the mamba-githook source code to the image
COPY debian /app/debian
COPY src /app/src
COPY LICENSE /app/LICENSE

# Build the mamba-githook package
RUN debuild --no-lintian -us -uc -b --post-clean

# Final Image for Running Integration Tests
# Final image will be minimal and only contain the necessary packages for running integration tests
FROM debian:bookworm

LABEL maintainer="Aydin Abdi" \
    description="Docker image for running integration tests for the mamba-githook package" \
    version="1.0.0"

# Environment Variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/Stockholm
ENV TERM=xterm-256color
ENV HOME="/home/mamba-user"
ENV INTEGRATION_TEST_DIR="${HOME}/tests/integration_tests"

# Set Up Working Directorys
WORKDIR $HOME

# Copy the mamba-githook package to the image
COPY --from=builder ../mamba-githook_*.deb $HOME/

# Copy test files and directories to the image
COPY tests $HOME/tests

# Install Runtime Dependencies
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    # mamba-githook dependencies
    fakeroot \
    curl \
    wget \
    git \
    aptitude \
    ca-certificates \
    # for running integration tests
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && update-ca-certificates

RUN aptitude update && aptitude install bats -y \
    && aptitude clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/* \
    && bats --version \
    # Install mamba-githook package
    && dpkg -i $HOME/mamba-githook_*.deb \
    && rm -rf $HOME/mamba-githook_*.deb

# Create a non-root user
RUN useradd -ms /bin/bash mamba-user \
    # Set correct permissions for the home directory and subdirectories
    && chown -R mamba-user:mamba-user $HOME \
    # Set correct permissions for mamba-githook package after installation
    && chown -R mamba-user:mamba-user /usr/bin/mamba-githook

# Set the user to use when running this image
USER mamba-user

# Set Default Command for running integration tests
CMD ["/bin/bash", "-c", "fakeroot bats ${INTEGRATION_TEST_DIR}/* -T --verbose-run --print-output-on-failure"]
