package collection

import (
	"strconv"
	"strings"
)

// Render renders a book collection.
func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case c == 1:
		id, err := strconv.Atoi(parts[0])
		if err != nil {
			return "Invalid collection ID"
		}

		cID := ID(id)
		collection, found := getCollection(cID)
		if !found {
			return "Book collection is empty"
		}

		return collection.Render()
	default:
		return "Not Found"
	}
}
