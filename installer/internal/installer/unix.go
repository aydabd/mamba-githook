package installer

import (
	"fmt"
	"os"
	"strings"

	"github.com/aydabd/mamba-githook/installer/internal/log"
)

func (i *Installer) setupUnixEnvironment(envVars []string) error {
	configFile := i.getShellConfigFile()
	if configFile == "" {
		return fmt.Errorf("unable to determine shell configuration file")
	}

	lines := make([]string, len(envVars))
	for j, envVar := range envVars {
		lines[j] = fmt.Sprintf("export %s", envVar)
	}

	return i.appendLinesToFile(configFile, lines)
}

func (i *Installer) removeUnixEnvironment() error {
	configFile := i.getShellConfigFile()
	if configFile == "" {
		return fmt.Errorf("unable to determine shell configuration file")
	}

	return i.removeLinesByContent(configFile, []string{i.BinDir, i.TargetDir})
}

func (i *Installer) checkUnixEnvVars() error {
	configFile := i.getShellConfigFile()
	content, err := os.ReadFile(configFile)
	if err != nil {
		return fmt.Errorf("failed to read shell config file: %w", err)
	}

	if !strings.Contains(string(content), i.BinDir) {
		log.Warn().Msg("mamba-githook directory is not in PATH")
	}

	if !strings.Contains(string(content), fmt.Sprintf("MAMBA_GITHOOK_DIR=%s", i.TargetDir)) {
		log.Warn().Msg("MAMBA_GITHOOK_DIR is not set correctly")
	}

	return nil
}
