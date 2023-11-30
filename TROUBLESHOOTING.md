# Troubleshooting

## Mambo-githook is not working

### Check the git hook is installed

create a new git repository and initialize it.

```bash
mkdir -p $HOME/test_repo && cd $HOME/test_repo
git init
```

check if the git hook is installed and based on the mamba-githook package.

```bash
cat .git/hooks/pre-commit | grep mamba-githook
```

## Pre-removal or post-installation script error

The package removal is failing due to an error in the pre-removal or post-installation script.
Manually editing or removing the script may allow the package to be removed successfully.

1. Navigate to `/var/lib/dpkg/info/`.
2. Edit or temporarily remove the pre-removal (`prerm`) and post-installation (`postinst`) scripts for the package.
These would be named `mamba-githook.prerm` and `mamba-githook.postinst`.

```bash
sudo rm /var/lib/dpkg/info/mamba-githook.prerm /var/lib/dpkg/info/mamba-githook.postinst
```

After doing this, try removing the package again:

```bash
sudo apt-get remove --purge mamba-githook
```

or

```bash
sudo dpkg -P --force-all mamba-githook
```

> **Caution:**
Proceed cautiously as manual intervention like this can be risky.

> **Note:**
force removal of the package will not modify the git configuration changes made by the package.
Global git config options that were modified are:
> - `core.hooksPath`
> - `init.templateDir`

Modify the git configuration manually to remove the changes made by the package.

> **Note:**

Micromamba can be removed before removing the package.

```bash
mamba-githook --uninstall-micromamba
```
