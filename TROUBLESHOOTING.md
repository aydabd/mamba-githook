# Troubleshooting

## mambo-githook is not working

### Try to clean up the package

If you have installed the package before, try to clean up the package and reinstall it.

```bash
sudo dpkg -P --force-all mamba-githook
sudo dpkg -i mamba-githook_0.0.1-1_all.deb
```

### Check the git hook

create a new git repository and initialize it.

```bash
mkdir -p $HOME/test_repo && cd $HOME/test_repo
git init
```

check if the git hook is installed.

```bash
cat .git/hooks/pre-commit
```

check if the hook is based on the mamba-githook package.

```bash
cat .git/hooks/pre-commit | grep mamba-githook
```




## Cleaning up

If you want to remove the package, run the following command:

```bash
sudo dpkg -r mamba-githook
```

## Uninstalling

If you want to uninstall the package, run the following command:

```bash
sudo dpkg -P mamba-githook
```

## Purge

If you want to purge the package, run the following command:

```bash
sudo dpkg -P --force-all mamba-githook
```
