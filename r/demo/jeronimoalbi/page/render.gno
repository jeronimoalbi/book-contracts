package page

import (
	"strings"

	"gno.land/p/demo/ufmt"
	"gno.land/r/demo/users"
)

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case path == "":
		return page.RenderHome()
	case path == "admin":
		return ufmt.Sprintf("%s", GetAdmin())
	case c == 2 && parts[0] == "balance":
		owner := users.AddressOrName(parts[1])
		balance, _ := page.BalanceOf(owner.Resolve())
		return ufmt.Sprintf("%d", balance)
	default:
		return "Not Found"
	}
}
