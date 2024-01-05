package testhelpers

import "testing"

func AssertPanicReason(t *testing.T, expected, actual string) {
	t.Helper()

	if expected != actual {
		t.Errorf("expected panic with '%s', got: '%s'", expected, actual)
	}
}
