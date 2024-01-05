package page

import (
	"std"
	"testing"

	"gno.land/p/demo/testutils"

	contract "gno.land/r/demo/jeronimoalbi/page"
)

func TestTotalSupply(t *testing.T) {
	if v := contract.TotalSupply(); v != initialSupply {
		t.Errorf("expected total supply to match initial supply %d, got %d", initialSupply, v)
	}
}

func TestBalanceOf(t *testing.T) {
	// Arrange
	admin := contract.GetAdmin()
	std.TestSetOrigCaller(admin)

	// Act
	balance := contract.BalanceOf(admin)

	// Assert
	if v := contract.TotalSupply(); v != balance {
		t.Errorf("expected admin balance to match total supply of %d, got: %d", v, balance)
	}
}

func TestTransfer(t *testing.T) {
	// Ararnge
	transferAmount := uint64(42)
	account := testutils.TestAddress("balance/account")

	admin := contract.GetAdmin()
	std.TestSetOrigCaller(admin)

	adminBalance := contract.BalanceOf(admin) - transferAmount

	// Act
	contract.Transfer(account, transferAmount)

	// Assert
	if v := contract.BalanceOf(account); v != transferAmount {
		t.Errorf("expected account balance to be %d, got %d", transferAmount, v)
	}

	if v := contract.BalanceOf(admin); v != adminBalance {
		t.Errorf("expected admin balance to be %d, got %d", adminBalance, v)
	}
}
