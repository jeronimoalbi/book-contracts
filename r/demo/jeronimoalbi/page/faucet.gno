package page

import "std"

const (
	maxAccountBalance = 10000
	mintAmount        = 100
)

func Faucet() {
	caller := std.PrevRealm().Addr()
	balance, err := page.BalanceOf(caller)
	if err != nil {
		panic(err)
	}

	if balance > maxAccountBalance {
		panic("account balance has enough tokens")
	}

	page.Mint(caller, mintAmount)
}
