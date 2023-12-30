package library

import (
	"std"
	"strings"
	"testing"

	"gno.land/p/demo/testutils"

	contract "gno.land/r/demo/jeronimoalbi/library"
)

func TestRender(t *testing.T) {
	owner := testutils.TestAddress("render/owner")
	std.TestSetOrigCaller(owner)

	cases := []struct {
		name   string
		path   string
		output string
		setup  func(*testing.T)
	}{
		{
			name:   "empty collection",
			path:   owner.String(),
			output: "Book collection is empty",
		},
		{
			name:   "ok",
			path:   owner.String(),
			output: "[#1] Foo\\n[#2] Bar\\n",
			setup: func(t *testing.T) {
				createBook(t, owner, "Foo")
				createBook(t, owner, "Bar")
			},
		},
		{
			name:   "not found",
			path:   "invalid/path/",
			output: "Not Found",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			if tc.setup != nil {
				tc.setup(t)
			}

			// Act
			output := contract.Render(tc.path)
			output = strings.ReplaceAll(output, "\n", "\\n")

			// Assert
			if output != tc.output {
				t.Errorf("expected output '%s', got: '%s'", tc.output, output)
			}
		})
	}
}
