package installer

import (
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"

	"github.com/aydabd/mamba-githook/installer/internal/log"
)

func detectShell() string {
	shell := os.Getenv("SHELL")
	if shell == "" {
		if runtime.GOOS == "windows" {
			return "cmd"
		}
		return "sh"
	}
	return filepath.Base(shell)
}

func (i *Installer) getShellConfigFile() string {
	homeDir, _ := os.UserHomeDir()

	switch i.Shell {
	case "bash":
		return filepath.Join(homeDir, ".bashrc")
	case "zsh":
		return filepath.Join(homeDir, ".zshrc")
	case "fish":
		return filepath.Join(homeDir, ".config", "fish", "config.fish")
	default:
		return filepath.Join(homeDir, ".profile")
	}
}

func (i *Installer) setupGitHooks() error {
	log.Info().Msg("Setting up Git hooks directory")

	cmd := exec.Command("git", "config", "--global", "core.hooksPath", filepath.Join(i.TargetDir, "hooks"))
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to set global Git hooks path: %w", err)
	}

	log.Info().Msg("Git hooks sets: " + filepath.Join(i.TargetDir, "hooks"))
	return nil
}

func (i *Installer) restoreGitHooks() error {
	log.Info().Msg("Restoring original Git hooks configuration")

	cmd := exec.Command("git", "config", "--global", "--unset", "core.hooksPath")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to unset global Git hooks path: %w", err)
	}

	log.Info().Msg("Original Git hooks configuration restored")
	return nil
}

func (i *Installer) createDirectories() error {
	dirs := []string{i.TargetDir, i.BinDir}
	for _, dir := range dirs {
		if err := os.MkdirAll(dir, 0755); err != nil {
			return fmt.Errorf("failed to create directory %s: %w", dir, err)
		}
	}
	return nil
}

func (i *Installer) copyDir(src, dst string) error {
	return filepath.Walk(src, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel(src, path)
		if err != nil {
			return err
		}

		dstPath := filepath.Join(dst, relPath)

		if info.IsDir() {
			return os.MkdirAll(dstPath, info.Mode())
		}

		return i.copyFile(path, dstPath)
	})
}

func (i *Installer) copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()

	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()

	_, err = io.Copy(out, in)
	if err != nil {
		return err
	}

	return out.Close()
}

func (i *Installer) appendLinesToFile(filename string, lines []string) error {
	f, err := os.OpenFile(filename, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0644)
	if err != nil {
		return err
	}
	defer f.Close()

	for _, line := range lines {
		if _, err := f.WriteString(line + "\n"); err != nil {
			return err
		}
	}

	return nil
}

func (i *Installer) removeLinesByContent(filename string, contents []string) error {
	input, err := os.ReadFile(filename)
	if err != nil {
		return err
	}

	lines := strings.Split(string(input), "\n")

	var newLines []string
	for _, line := range lines {
		keep := true
		for _, content := range contents {
			if strings.Contains(line, content) {
				keep = false
				break
			}
		}
		if keep {
			newLines = append(newLines, line)
		}
	}

	output := strings.Join(newLines, "\n")
	return os.WriteFile(filename, []byte(output), 0644)
}

func (i *Installer) checkGitHooks() error {
	cmd := exec.Command("git", "config", "--global", "core.hooksPath")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to get Git hooks path: %w", err)
	}

	hooksPath := strings.TrimSpace(string(output))
	expectedPath := filepath.Join(i.TargetDir, "hooks")

	if hooksPath != expectedPath {
		log.Warn().Msgf("Git hooks path is not set correctly. Expected: %s, Got: %s", expectedPath, hooksPath)
	}

	return nil
}

// copyProjectFiles copies the project files from the embedded filesystem to the target directory
func (i *Installer) copyProjectFiles() error {
	log.Info().Msg("Copying mamba-githook files")

	err := fs.WalkDir(i.SrcFS, "src", func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		relPath, err := filepath.Rel("src", path)
		if err != nil {
			return err
		}

		var dstPath string
		var mode os.FileMode = 0644 // Default mode for regular files

		switch {
		case relPath == "mamba-githook":
			dstPath = filepath.Join(i.BinDir, "mamba-githook")
			mode = 0755 // Executable
		case relPath == "mamba-githook.1":
			if i.OS == "windows" {
				// Skip man page on Windows
				return nil
			}
			manDir, err := i.getManPageDir()
			if err != nil {
				return err
			}
			dstPath = filepath.Join(manDir, "mamba-githook.1")
		case strings.HasPrefix(relPath, "hooks/"):
			dstPath = filepath.Join(i.TargetDir, relPath)
			mode = 0755 // Executable
		default:
			dstPath = filepath.Join(i.TargetDir, relPath)
		}

		if d.IsDir() {
			return os.MkdirAll(dstPath, 0755)
		}

		srcFile, err := i.SrcFS.Open(path)
		if err != nil {
			return err
		}
		defer srcFile.Close()

		dstFile, err := os.CreateTemp(filepath.Dir(dstPath), "temp-*")
		if err != nil {
			return err
		}
		tempPath := dstFile.Name()
		defer os.Remove(tempPath) // Clean up in case of failure

		_, err = io.Copy(dstFile, srcFile)
		if err != nil {
			dstFile.Close()
			return err
		}
		dstFile.Close()

		if err := os.Chmod(tempPath, mode); err != nil {
			return err
		}

		return os.Rename(tempPath, dstPath)
	})

	if err != nil {
		return fmt.Errorf("failed to copy mamba-githook files: %w", err)
	}

	log.Info().Msg("Mamba-githook files copied successfully")
	return nil
}

// getManPageDir returns the appropriate directory for man pages based on the OS
// and ensures that the directory exists
func (i *Installer) getManPageDir() (string, error) {
	var manDir string
	switch i.OS {
	case "darwin", "linux":
		manDir = filepath.Join(i.HomeDir, ".local", "share", "man", "man1")
	default:
		// This shouldn't be reached due to the check in copyProjectFiles,
		// but we'll provide a default just in case
		manDir = filepath.Join(i.TargetDir, "man", "man1")
	}

	// Ensure the man page directory exists
	if err := os.MkdirAll(manDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create man page directory %s: %w", manDir, err)
	}

	return manDir, nil
}

func (i *Installer) setPermissions(dir string) error {
	return filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return os.Chmod(path, 0755)
		}
		if strings.HasSuffix(path, "mamba-githook") || strings.HasPrefix(filepath.Base(filepath.Dir(path)), "hooks") {
			return os.Chmod(path, 0755)
		}
		return os.Chmod(path, 0644)
	})
}
