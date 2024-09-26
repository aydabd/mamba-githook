# mamba-githook

Seamlessly integrate Git hooks with Micromamba environments.

## Description

`mamba-githook` is a specialized solution designed to facilitate the seamless
integration of Git-hooks with Micromamba environments. Aimed at both individual
developers and large teams, this Debian package automates the setup, configuration,
and management of code quality tools, all encapsulated within an isolated,
reproducible Micromamba environment.

Simplify your workflow and enforce code quality standards across projects.

## Installation

### Install the Debian package or install ubuntu package

```bash
# Download artifact from github release version
sudo dpkg -i mamba-githook_<version>*.db
```
for ubuntu installation:
```bash
sudo add-apt-repository ppa:aydabd/mamba-githook
sudo apt-get update
sudo apt-get install mamba-githook
```

Note: If Micromamba is already installed, it will be skipped.


## Install for other platforms with go installer

Check the latest release version and desired OS/ARCH from the [releases page](https://github.com/aydabd/mamba-githook/releases).

```bash
# Get the binary and run help command
curl -L https://github.com/aydabd/mamba-githook/releases/download/1.0.1/mamba-githook-installer-darwin-arm64 -o mamba-githook-installer && chmod +x mamba-githook-installer && ./mamba-githook-installer --help


# Install the latest version
curl -L https://github.com/aydabd/mamba-githook/releases/download/1.0.1/mamba-githook-installer-darwin-arm64 -o mamba-githook-installer && chmod +x mamba-githook-installer && ./mamba-githook-installer install

# Chech th status
./mamba-githook-installer status
```

## Uninstall the Debian package

```bash
sudo apt-get remove mamba-githook
```

## Uninstall for other platforms with go installer

```bash
# Uninstall the latest version
./mamba-githook-installer uninstall
```

## How to use

1. Configure git hooks for a specific git repository and create sample:
```bash
cd /path/to/git/repo && mamba-githook init-project --create-sample
```

Note: If the git repository is already has a custom hook directory, it will be skipped.

2. Now commit the files and push to the remote repository.
The git hook will run the script files in the custom hook directory.

If any of the commands fail, the commit will be aborted.

For more information and usage:

  ```bash
  mamba-githook --help
  ```

## Manual Configuration

1. Create a hook directory in the git repository:

```bash
mkdir -p path/to/repo/.githooks.d && cd path/to/repo/.githooks.d
```

2. Create a micromamba environment yml file for specified hook: `pre-commit_environment.yml` (see example below)

## Example

```bash
echo <<EOF
name: my-env
  channels:
  - conda-forge
  - nodefaults
dependencies:
  - python
  - pre-commit
  - flake8
  - pytest
  - black
  - mypy
  - nodejs
  - git
  - curl
EOF > pre-commit_environment.yml
```

2. Create a pre-commit.40.linters file: `pre-commit.40.linters` (see example below)

```bash
echo <<EOF
#!/bin/bash
set -e

# Set the project githooks directory, otherwise use the default value
: "${MAMBA_GITHOOK_PROJECT_GITHOOKS_DIR:=".githooks.d"}"

# Run pre-commit
pre-commit run --all-files -c "${MAMBA_GITHOOK_PROJECT_GITHOOKS_DIR}/.pre-commit-config.yaml"

# Run pytest
pytest

# Run flake8
flake8

# Run black
black --check .

# Run mypy
mypy .

# Run npm install
npm install

# Run npm run build
npm run build

# Run npm run lint
npm run lint
EOF > pre-commit.40.linters

# Make the file executable
chmod +x pre-commit.40.linters
```

## Usage

Once the git repository is initialized and the configuration files are created,
commit the files and push to the remote repository. The git hook will run the
script files in the `.githooks.d` directory.

If any of the commands fail, the commit will be aborted.

For more information and usage:

  ```bash
  mamba-githook --help
  ```

## Troubleshooting

For troubleshooting, please refer to the [Troubleshooting](TROUBLESHOOTING.md)

## Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

## License

[MIT](LICENSE)
