package installer

import (
	"embed"
	"fmt"
	"os"
	"path/filepath"
	"runtime"

	"github.com/aydabd/mamba-githook/installer/internal/log"
)

type Installer struct {
	SrcFS      embed.FS
	HomeDir    string
	TargetDir  string
	BinDir     string
	BackupDir  string
	OS         string
	Shell      string
	ProjectDir string
}

func NewInstaller(srcFS embed.FS) *Installer {
	// Determine the target and binary directories based on the OS
	homeDir, _ := os.UserHomeDir()
	var targetDir, binDir string
	osType := runtime.GOOS

	switch osType {
	case "windows":
		targetDir = filepath.Join(homeDir, "AppData", "Local", "mamba-githook")
		binDir = filepath.Join(homeDir, "AppData", "Local", "bin")
	case "darwin", "linux":
		targetDir = filepath.Join(homeDir, ".local", "share", "mamba-githook")
		binDir = filepath.Join(homeDir, ".local", "bin")
	default:
		log.Fatal().Msgf("Unsupported OS: %s", osType)
	}

	backupDir := filepath.Join(homeDir, ".mamba-githook-backup")
	shell := detectShell()

	// Calculate the project root directory (one level up from the installer directory)
	execPath, err := os.Executable()
	if err != nil {
		log.Fatal().Err(err).Msg("Failed to get executable path")
	}

	installerDir := filepath.Dir(execPath)
	projectDir := filepath.Dir(installerDir)

	return &Installer{
		SrcFS:      srcFS,
		HomeDir:    homeDir,
		TargetDir:  targetDir,
		BinDir:     binDir,
		BackupDir:  backupDir,
		OS:         osType,
		Shell:      shell,
		ProjectDir: projectDir,
	}
}

func (i *Installer) Install() error {
	log.Info().Msg("Starting mamba-githook installation")

	if err := i.createDirectories(); err != nil {
		return fmt.Errorf("failed to create directories: %w", err)
	}

	if err := i.copyProjectFiles(); err != nil {
		return fmt.Errorf("failed to copy project files: %w", err)
	}

	if err := i.setupEnvironment(); err != nil {
		return fmt.Errorf("failed to set up environment: %w", err)
	}

	if err := i.setupGitHooks(); err != nil {
		return fmt.Errorf("failed to set up Git hooks: %w", err)
	}

	log.Info().Msg("mamba-githook has been successfully installed")
	return nil
}

func (i *Installer) setupEnvironment() error {
	envVars := []string{
		fmt.Sprintf("PATH=$PATH:%s", i.BinDir),
		fmt.Sprintf("MAMBA_GITHOOK_DIR=%s", i.TargetDir),
	}

	if i.OS == "windows" {
		return i.setupWindowsEnvironment(envVars)
	}
	return i.setupUnixEnvironment(envVars)
}

func (i *Installer) removeEnvironment() error {
	if i.OS == "windows" {
		return i.removeWindowsEnvironment()
	}
	return i.removeUnixEnvironment()
}

func (i *Installer) Uninstall() error {
	log.Info().Msg("Starting mamba-githook uninstallation")

	if err := os.RemoveAll(i.TargetDir); err != nil {
		return fmt.Errorf("failed to remove target directory: %w", err)
	}
	if err := os.Remove(filepath.Join(i.BinDir, "mamba-githook")); err != nil && !os.IsNotExist(err) {
		return fmt.Errorf("failed to remove mamba-githook binary: %w", err)
	}

	if err := os.Remove(filepath.Join(i.HomeDir, ".local", "share", "man", "man1", "mamba-githook.1")); err != nil {
		return fmt.Errorf("failed to remove mamba-githook man page: %w", err)
	}

	if err := i.removeEnvironment(); err != nil {
		return fmt.Errorf("failed to remove environment variables: %w", err)
	}

	if err := i.restoreGitHooks(); err != nil {
		return fmt.Errorf("failed to restore Git hooks: %w", err)
	}

	log.Info().Msg("mamba-githook has been successfully uninstalled")
	return nil
}

func (i *Installer) Upgrade() error {
	log.Info().Msg("Starting mamba-githook upgrade")

	if err := i.Backup(); err != nil {
		return fmt.Errorf("failed to create backup: %w", err)
	}

	if err := i.Uninstall(); err != nil {
		return fmt.Errorf("failed to uninstall previous version: %w", err)
	}

	if err := i.Install(); err != nil {
		if restoreErr := i.Restore(); restoreErr != nil {
			log.Error().Err(restoreErr).Msg("Failed to restore from backup after failed upgrade")
		}
		return fmt.Errorf("failed to install new version: %w", err)
	}

	log.Info().Msg("mamba-githook has been successfully upgraded")
	return nil
}

func (i *Installer) Backup() error {
	log.Info().Msg("Creating backup")

	if err := os.MkdirAll(i.BackupDir, 0755); err != nil {
		return fmt.Errorf("failed to create backup directory: %w", err)
	}

	if err := i.copyDir(i.TargetDir, filepath.Join(i.BackupDir, "target")); err != nil {
		return fmt.Errorf("failed to backup target directory: %w", err)
	}

	if err := i.copyFile(filepath.Join(i.BinDir, "mamba-githook"), filepath.Join(i.BackupDir, "mamba-githook")); err != nil {
		return fmt.Errorf("failed to backup mamba-githook binary: %w", err)
	}

	log.Info().Msg("Backup created successfully")
	return nil
}

func (i *Installer) Restore() error {
	log.Info().Msg("Starting restore from backup")

	// Check if backup exists
	if _, err := os.Stat(i.BackupDir); os.IsNotExist(err) {
		return fmt.Errorf("backup directory does not exist: %w", err)
	}

	// Create a temporary directory for restoration
	tempDir, err := os.MkdirTemp("", "mamba-githook-restore-")
	if err != nil {
		return fmt.Errorf("failed to create temporary directory: %w", err)
	}
	defer os.RemoveAll(tempDir)

	// Restore to temporary directory first
	if err := i.copyDir(filepath.Join(i.BackupDir, "target"), filepath.Join(tempDir, "target")); err != nil {
		return fmt.Errorf("failed to restore target directory: %w", err)
	}

	if err := i.copyFile(filepath.Join(i.BackupDir, "mamba-githook"), filepath.Join(tempDir, "mamba-githook")); err != nil {
		return fmt.Errorf("failed to restore mamba-githook binary: %w", err)
	}

	// Restore man page if it exists and we're not on Windows
	if i.OS != "windows" {
		manPageSrc := filepath.Join(i.BackupDir, "man", "man1", "mamba-githook.1")
		if _, err := os.Stat(manPageSrc); err == nil {
			manPageDst := filepath.Join(tempDir, "man", "man1", "mamba-githook.1")
			if err := i.copyFile(manPageSrc, manPageDst); err != nil {
				return fmt.Errorf("failed to restore man page: %w", err)
			}
		}
	}

	// Set correct permissions
	if err := i.setPermissions(tempDir); err != nil {
		return fmt.Errorf("failed to set permissions: %w", err)
	}

	// Move temporary directory to final location
	if err := os.RemoveAll(i.TargetDir); err != nil {
		return fmt.Errorf("failed to remove existing target directory: %w", err)
	}
	if err := os.Rename(filepath.Join(tempDir, "target"), i.TargetDir); err != nil {
		return fmt.Errorf("failed to move restored files to target directory: %w", err)
	}
	if err := os.Rename(filepath.Join(tempDir, "mamba-githook"), filepath.Join(i.BinDir, "mamba-githook")); err != nil {
		return fmt.Errorf("failed to move restored binary: %w", err)
	}

	// Restore man page if not on Windows
	if i.OS != "windows" {
		manPageSrc := filepath.Join(tempDir, "man", "man1", "mamba-githook.1")
		if _, err := os.Stat(manPageSrc); err == nil {
			manPageDir, err := i.getManPageDir()
			if err != nil {
				return fmt.Errorf("failed to get man page directory: %w", err)
			}
			if err := os.Rename(manPageSrc, filepath.Join(manPageDir, "mamba-githook.1")); err != nil {
				return fmt.Errorf("failed to move restored man page: %w", err)
			}
		}
	}

	log.Info().Msg("Restore completed successfully")
	return nil
}

func (i *Installer) Status() error {
	log.Info().Msg("Checking mamba-githook installation status")

	if _, err := os.Stat(i.TargetDir); os.IsNotExist(err) {
		log.Info().Msg("mamba-githook is not installed")
		return nil
	}

	binaryPath := filepath.Join(i.BinDir, "mamba-githook")
	if _, err := os.Stat(binaryPath); os.IsNotExist(err) {
		log.Info().Msg("mamba-githook binary is missing")
		return nil
	}

	if i.OS == "windows" {
		if err := i.checkWindowsEnvVars(); err != nil {
			return err
		}
	} else {
		if err := i.checkUnixEnvVars(); err != nil {
			return err
		}
	}

	if err := i.checkGitHooks(); err != nil {
		return err
	}

	log.Info().Msg("mamba-githook is properly installed and configured")
	return nil
}

func (i *Installer) NonInteractiveInstall() error {
	log.Info().Msg("Starting non-interactive mamba-githook installation")
	return i.Install()
}
