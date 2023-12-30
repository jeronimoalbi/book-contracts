package library

import (
	"fmt"
	"std"
	"strings"
	"testing"

	"gno.land/p/demo/testutils"

	contract "gno.land/r/demo/jeronimoalbi/library"
)

func TestRender(t *testing.T) {
	ownerWithoutBooks := testutils.TestAddress("render/owner2")

	owner := testutils.TestAddress("render/owner")
	bookID1 := createBook(t, owner, "Foo")
	bookID2 := createBook(t, owner, "Bar")

	std.TestSetOrigCaller(owner)

	cases := []struct {
		name   string
		path   string
		output string
	}{
		{
			name:   "empty collection",
			path:   ownerWithoutBooks.String(),
			output: "Book collection is empty",
		},
		{
			name:   "ok",
			path:   owner.String(),
			output: fmt.Sprintf("[#%d] Foo\\n[#%d] Bar\\n", bookID1, bookID2),
		},
		{
			name:   "not found",
			path:   "invalid/path/",
			output: "Not Found",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
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
