package page

import (
	"fmt"
	"std"
	"testing"

	"gno.land/p/demo/jeronimoalbi/testhelpers"

	contract "gno.land/r/demo/jeronimoalbi/page"
)

func TestFaucet(t *testing.T) {
	cases := []struct {
		name    string
		balance uint64
		err     string
	}{
		{
			name:    "ok",
			balance: 200,
		},
		{
			name:    "fail",
			balance: maxAccountBalance + 1,
			err:     "account balance has enough tokens",
		},
	}

	for i, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			caller := testhelpers.TestAddress(fmt.Sprintf("faucet/caller%d", i))

			if tc.balance > 0 {
				admin := contract.GetAdmin()
				std.TestSetOrigCaller(admin)
				contract.Transfer(caller, tc.balance)
			}

			balance := contract.BalanceOf(caller)
			wantBalance := balance + mintAmount

			std.TestSetOrigCaller(caller)

			// Act
			reason := testhelpers.HandlePanic(t, func() {
				contract.Faucet()
			})

			// Assert
			if tc.err != "" {
				testhelpers.AssertPanicReason(t, tc.err, reason)
			} else {
				if v := contract.BalanceOf(caller); v != wantBalance {
					t.Errorf("expected balance to be %dpage, got %dpage", wantBalance, v)
				}
			}
		})
	}
}
