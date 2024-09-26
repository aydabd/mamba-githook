#syntax=docker/dockerfile:1
# This Dockerfile is used to build the application
# in a multi-stage build process. The first stage
# is used to download all dependencies and the second
# stage is used to build the application.

# Usage:
#   docker build -t <image-name> .
#   docker run -v $(pwd)/_build:/_build <image-name>

# Stage 1: Base image for downloading dependencies
FROM golang:1.23-alpine AS base

# Set the working directory inside the container
WORKDIR /app

# Copy the entire project (including the parent directory)
COPY installer/go.mod installer/go.sum /app/installer/

# Download all dependencies
RUN cd installer && go mod download

# Stage 2: Builder stage for building the application
FROM base AS builder

WORKDIR /app

# Copy src into cmd directory which will be embedded into the final binary
COPY src /app/installer/cmd/src

# Copy the installer package
COPY installer/cmd /app/installer/cmd
COPY installer/internal /app/installer/internal

# Copy installer/build-all script with executable permissions
COPY --chmod=0655 installer/build-all /app/installer/build-all

WORKDIR /app/installer

VOLUME /_build

# Default command to execute the build-all script
CMD ["./build-all"]

