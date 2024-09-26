package main

import (
	"github.com/aydabd/mamba-githook/installer/internal/installer"
	"github.com/aydabd/mamba-githook/installer/internal/log"
	"github.com/spf13/cobra"
)

var (
	rootCmd = &cobra.Command{
		Use:   "mamba-githook-installer",
		Short: "Installer for mamba-githook",
		Long:  `A cross-platform installer for mamba-githook that handles installation, uninstallation, and updates.`,
	}

	verbose bool
)

func init() {
	rootCmd.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "Enable verbose output")
	rootCmd.PersistentPreRun = func(cmd *cobra.Command, args []string) {
		if verbose {
			log.SetVerbose()
		}
	}
}

func main() {
	inst := installer.NewInstaller(srcFS)

	rootCmd.AddCommand(
		createInstallCmd(inst),
		createUninstallCmd(inst),
		createUpgradeCmd(inst),
		createBackupCmd(inst),
		createRestoreCmd(inst),
		createStatusCmd(inst),
	)

	if err := rootCmd.Execute(); err != nil {
		log.Fatal().Err(err).Msg("Failed to execute command")
	}
}

func createInstallCmd(inst *installer.Installer) *cobra.Command {
	var nonInteractive bool
	cmd := &cobra.Command{
		Use:   "install",
		Short: "Install mamba-githook",
		Run: func(cmd *cobra.Command, args []string) {
			var err error
			if nonInteractive {
				err = inst.NonInteractiveInstall()
			} else {
				err = inst.Install()
			}
			if err != nil {
				log.Fatal().Err(err).Msg("Installation failed")
			}
		},
	}
	cmd.Flags().BoolVarP(&nonInteractive, "non-interactive", "n", false, "Run in non-interactive mode")
	return cmd
}

func createUninstallCmd(inst *installer.Installer) *cobra.Command {
	return &cobra.Command{
		Use:   "uninstall",
		Short: "Uninstall mamba-githook",
		Run: func(cmd *cobra.Command, args []string) {
			if err := inst.Uninstall(); err != nil {
				log.Fatal().Err(err).Msg("Uninstallation failed")
			}
		},
	}
}

func createUpgradeCmd(inst *installer.Installer) *cobra.Command {
	return &cobra.Command{
		Use:   "upgrade",
		Short: "Upgrade mamba-githook",
		Run: func(cmd *cobra.Command, args []string) {
			if err := inst.Upgrade(); err != nil {
				log.Fatal().Err(err).Msg("Upgrade failed")
			}
		},
	}
}

func createBackupCmd(inst *installer.Installer) *cobra.Command {
	return &cobra.Command{
		Use:   "backup",
		Short: "Backup mamba-githook installation",
		Run: func(cmd *cobra.Command, args []string) {
			if err := inst.Backup(); err != nil {
				log.Fatal().Err(err).Msg("Backup failed")
			}
		},
	}
}

func createRestoreCmd(inst *installer.Installer) *cobra.Command {
	return &cobra.Command{
		Use:   "restore",
		Short: "Restore mamba-githook installation from backup",
		Run: func(cmd *cobra.Command, args []string) {
			if err := inst.Restore(); err != nil {
				log.Fatal().Err(err).Msg("Restore failed")
			}
		},
	}
}

func createStatusCmd(inst *installer.Installer) *cobra.Command {
	return &cobra.Command{
		Use:   "status",
		Short: "Check the status of mamba-githook installation",
		Run: func(cmd *cobra.Command, args []string) {
			if err := inst.Status(); err != nil {
				log.Fatal().Err(err).Msg("Status check failed")
			}
		},
	}
}
