package page

import (
	"std"

	"gno.land/p/demo/grc/grc20"
)

const initialSupply = 1000000 * 10000

var (
	page  *grc20.AdminToken
	admin std.Address = "g13m34fka0rqw7p03axtg26l8k29sunvzua6zk58"
)

func init() {
	page = grc20.NewAdminToken("Page", "page", 4)
	page.Mint(admin, initialSupply)
}

func GetAdmin() std.Address {
	return admin
}

func TotalSupply() uint64 {
	return page.TotalSupply()
}

func BalanceOf(owner std.Address) uint64 {
	balance, err := page.BalanceOf(owner)
	if err != nil {
		panic(err)
	}
	return balance
}

func Allowance(owner, spender std.Address) uint64 {
	allowance, err := page.Allowance(owner, spender)
	if err != nil {
		panic(err)
	}
	return allowance
}

func Transfer(to std.Address, amount uint64) {
	caller := std.GetOrigCaller()
	if err := page.Transfer(caller, to, amount); err != nil {
		panic(err)
	}
}

func Approve(spender std.Address, amount uint64) {
	caller := std.GetOrigCaller()
	if err := page.Approve(caller, spender, amount); err != nil {
		panic(err)
	}
}

func TransferFrom(from, to std.Address, amount uint64) {
	caller := std.GetOrigCaller()
	if err := page.TransferFrom(caller, from, to, amount); err != nil {
		panic(err)
	}
}

func Mint(address std.Address, amount uint64) {
	caller := std.GetOrigCaller()
	assertIsAdmin(caller)
	if err := page.Mint(address, amount); err != nil {
		panic(err)
	}
}

func Burn(address std.Address, amount uint64) {
	caller := std.GetOrigCaller()
	assertIsAdmin(caller)
	if err := page.Burn(address, amount); err != nil {
		panic(err)
	}
}

func assertIsAdmin(address std.Address) {
	if address != admin {
		panic("restricted access")
	}
}
