// Embeds the src directory into the binary.
// The src directory contains the files which represent the mamba-githook source code.
// The src directory is embedded into the binary so that the binary can be distributed as a single file.
// The directive `//go:embed all:src` is a build constraint that tells the go tool to embed the src directory into the binary.
// Notice: src directory shall be in the same directory as the embed.go file.
// In this case when we build by container, the src will be copied where the embed.go is.
package main

import (
	"embed"
)

//go:embed all:src
var srcFS embed.FS
