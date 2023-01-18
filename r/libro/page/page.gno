package page

import (
	"std"
	"strings"

	"gno.land/p/demo/grc/grc20"
	"gno.land/p/demo/ufmt"
	"gno.land/r/demo/users"
)

var (
	admin std.Address
	page  *grc20.AdminToken
)

func init() {
	admin = std.GetOrigCaller()
	page = grc20.NewAdminToken("Page", "PAGE", 4)
	page.Mint(admin, 1000000*10000)
}

func GetAdmin() string {
	return admin.String()
}

func TotalSupply() uint64 {
	return page.TotalSupply()
}

func BalanceOf(owner users.AddressOrName) uint64 {
	balance, err := page.BalanceOf(owner.Resolve())
	if err != nil {
		panic(err)
	}
	return balance
}

func Allowance(owner, spender users.AddressOrName) uint64 {
	allowance, err := page.Allowance(owner.Resolve(), spender.Resolve())
	if err != nil {
		panic(err)
	}
	return allowance
}

func Transfer(to users.AddressOrName, amount uint64) {
	caller := std.GetOrigCaller()
	page.Transfer(caller, to.Resolve(), amount)
}

func Approve(spender users.AddressOrName, amount uint64) {
	caller := std.GetOrigCaller()
	page.Approve(caller, spender.Resolve(), amount)
}

func TransferFrom(from, to users.AddressOrName, amount uint64) {
	caller := std.GetOrigCaller()
	page.TransferFrom(caller, from.Resolve(), to.Resolve(), amount)
}

func Faucet() {
	caller := std.GetOrigCaller()
	balance, err := page.BalanceOf(caller)
	if err != nil {
		panic(err)
	}

	// Limit faucet to 10k per account
	if balance > 9000*10000 {
		panic("account balance has enough tokens")
	}

	page.Mint(caller, 1000*10000)
}

func Mint(address users.AddressOrName, amount uint64) {
	caller := std.GetOrigCaller()
	assertIsAdmin(caller)
	page.Mint(address.Resolve(), amount)
}

func Burn(address users.AddressOrName, amount uint64) {
	caller := std.GetOrigCaller()
	assertIsAdmin(caller)
	page.Burn(address.Resolve(), amount)
}

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

func assertIsAdmin(address std.Address) {
	if address != admin {
		panic("restricted access")
	}
}
