package testhelpers

import (
	"std"

	"gno.land/p/demo/testutils"
)

func TestAddress(name string) std.Address {
	return testutils.TestAddress(name)
}
