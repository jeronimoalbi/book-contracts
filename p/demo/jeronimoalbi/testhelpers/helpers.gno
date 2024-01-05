package testhelpers

import (
	"fmt"
	"strings"
	"testing"
)

func Flattern(t *testing.T, output string) string {
	t.Helper()

	return strings.ReplaceAll(output, "\n", "\\n")
}

func HandlePanic(t *testing.T, fn func()) (reason string) {
	t.Helper()

	defer func() {
		if r := recover(); r != nil {
			if err, _ := r.(error); err != nil {
				reason = err.Error()
			} else {
				reason = fmt.Sprint(r)
			}
		}
	}()

	fn()
	return
}
