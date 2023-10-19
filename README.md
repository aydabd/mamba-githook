# mamba-githook

Seamlessly integrate Git-hooks with Micromamba environments.

## Description

`mamba-githook` is a specialized solution designed to facilitate the seamless integration of Git-hooks with Micromamba virtual environments. Aimed at both individual developers and large teams, this Debian package automates the setup, configuration, and management of code quality tools, all encapsulated within an isolated, reproducible Micromamba environment. Simplify your workflow and enforce code quality standards across projects with MambaGitHooks.

## Installation

1. Install the Debian package: `sudo dpkg -i mamba-githook_0.0.1-1_all.deb`
2. Initialize a new git repository: `git init`

## Configuration

1. Create a micromamba environemnet yml file: `environment.yml` (see example below)

## Example

```yaml
name: my-env
channels:
  - conda-forge
dependencies:
    - python
    - pip
    - pre-commit
    - flake8
    - pytest
    - black
    - mypy
    - nodejs
    - git
    - curl
```

2. Create a pre_commit_commands.sh file: `pre_commit_commands.sh` (see example below)

```bash
#!/bin/bash

# Run pre-commit
pre-commit run --all-files

# Run pytest
pytest

# Run flake8
flake8

# Run black
black -l 120 .

# Run mypy
mypy .

# Run npm install
npm install

# Run npm run build
npm run build
```

## Usage

Once the git repository is initialized and the configuration files are created,
commit the files and push to the remote repository. The git hook will run the
commands in the pre_commit_commands.sh file before the commit is completed.

If any of the commands fail, the commit will be aborted.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.

## License

[MIT](LICENSE)
