package log

import (
	"context"
	"fmt"
	"io"
	"os"
	"time"

	"github.com/rs/zerolog"
)

var defaultLogger Logger

type Logger struct {
	zl zerolog.Logger
}

func init() {
	output := zerolog.ConsoleWriter{
		Out:        os.Stdout,
		TimeFormat: time.RFC3339,
		FormatMessage: func(i interface{}) string {
			return fmt.Sprintf("%-50s", i)
		},
		FormatFieldName: func(i interface{}) string {
			return fmt.Sprintf("%s:", i)
		},
		FormatFieldValue: func(i interface{}) string {
			return fmt.Sprintf("%s", i)
		},
	}

	zl := zerolog.New(output).With().Timestamp().Caller().Logger()
	defaultLogger = Logger{zl: zl}

	// Set default level to Info
	SetGlobalLevel(zerolog.InfoLevel)
}

func SetGlobalLevel(level zerolog.Level) {
	zerolog.SetGlobalLevel(level)
}

func SetVerbose() {
	SetGlobalLevel(zerolog.DebugLevel)
}

func SetOutput(w io.Writer) {
	defaultLogger.zl = defaultLogger.zl.Output(w)
}

// Debug starts a new message with debug level.
func Debug() *zerolog.Event {
	return defaultLogger.zl.Debug()
}

// Info starts a new message with info level.
func Info() *zerolog.Event {
	return defaultLogger.zl.Info()
}

// Warn starts a new message with warn level.
func Warn() *zerolog.Event {
	return defaultLogger.zl.Warn()
}

// Error starts a new message with error level.
func Error() *zerolog.Event {
	return defaultLogger.zl.Error()
}

// Fatal starts a new message with fatal level. The os.Exit(1) function
// is called by the Msg method.
func Fatal() *zerolog.Event {
	return defaultLogger.zl.Fatal()
}

// Panic starts a new message with panic level. The panic() function
// is called by the Msg method.
func Panic() *zerolog.Event {
	return defaultLogger.zl.Panic()
}

// WithLevel starts a new message with level.
func WithLevel(level zerolog.Level) *zerolog.Event {
	return defaultLogger.zl.WithLevel(level)
}

// Log starts a new message with no level. Setting zerolog.GlobalLevel to
// zerolog.Disabled will still disable events produced by this method.
func Log() *zerolog.Event {
	return defaultLogger.zl.Log()
}

// Print sends a log event using debug level and no extra field.
// Arguments are handled in the manner of fmt.Print.
func Print(v ...interface{}) {
	defaultLogger.zl.Print(v...)
}

// Printf sends a log event using debug level and no extra field.
// Arguments are handled in the manner of fmt.Printf.
func Printf(format string, v ...interface{}) {
	defaultLogger.zl.Printf(format, v...)
}

// Ctx returns the Logger associated with the ctx. If no logger
// is associated, a disabled logger is returned.
func Ctx(ctx context.Context) *Logger {
	return &Logger{zl: *zerolog.Ctx(ctx)}
}

// With creates a child logger with the field added to its context.
func With() zerolog.Context {
	return defaultLogger.zl.With()
}
