package library

import (
	"std"
	"strconv"
	"strings"

	"gno.land/p/demo/jeronimoalbi/book"
)

// Render renders a book collection.
func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case c == 1:
		address := std.Address(parts[0])
		collection, found := library.GetCollection(address)
		if !found {
			return "Book collection is empty"
		}
		return collection.Render()
	default:
		return "Not Found"
	}
}
