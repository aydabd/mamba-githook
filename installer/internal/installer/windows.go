package installer

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/aydabd/mamba-githook/installer/internal/log"
)

func (i *Installer) setupWindowsEnvironment(envVars []string) error {
	for _, envVar := range envVars {
		parts := strings.SplitN(envVar, "=", 2)
		cmd := exec.Command("setx", parts[0], parts[1])
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to set environment variable %s: %w", parts[0], err)
		}
	}
	return nil
}

func (i *Installer) removeWindowsEnvironment() error {
	envVars := []string{"PATH", "MAMBA_GITHOOK_DIR"}
	for _, envVar := range envVars {
		cmd := exec.Command("reg", "delete", "HKCU\\Environment", "/F", "/V", envVar)
		if err := cmd.Run(); err != nil {
			return fmt.Errorf("failed to remove environment variable %s: %w", envVar, err)
		}
	}
	return nil
}

func (i *Installer) checkWindowsEnvVars() error {
	path := os.Getenv("PATH")
	if !strings.Contains(path, i.BinDir) {
		log.Warn().Msg("mamba-githook directory is not in PATH")
	}

	mambaGithookDir := os.Getenv("MAMBA_GITHOOK_DIR")
	if mambaGithookDir != i.TargetDir {
		log.Warn().Msg("MAMBA_GITHOOK_DIR is not set correctly")
	}

	return nil
}
