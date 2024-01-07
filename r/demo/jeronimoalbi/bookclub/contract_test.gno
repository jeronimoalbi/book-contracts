// Contract tests
//
// All tests change the virtual machine state and are not atomic
// so when a test changes the state it affect the tests that are
// executed after.
package bookclub

import (
	"fmt"
	"std"
	"testing"

	"gno.land/p/demo/jeronimoalbi/book"
	"gno.land/p/demo/jeronimoalbi/testhelpers"
	"gno.land/r/demo/jeronimoalbi/library"
	"gno.land/r/demo/jeronimoalbi/page"

	contract "gno.land/r/demo/jeronimoalbi/bookclub"
)

func TestLend(t *testing.T) {
	pkgAddr := std.DerivePkgAddr("gno.land/r/demo/jeronimoalbi/bookclub")

	cases := []struct {
		name          string
		send          std.Coins
		borrowingDays uint64
		err           string
	}{
		{
			name: "invalid borrowing period",
			send: std.Coins{{"page", 1}},
			err:  "The minimum borrowing period is one day",
		},
		{
			name:          "send two coins",
			send:          std.Coins{{"page", 10}, {"ugnot", 42}},
			borrowingDays: 1,
			err:           "Send only one type of coin",
		},
		{
			name:          "min deposit",
			send:          std.Coins{{"page", 0}},
			borrowingDays: 1,
			err:           "An invalid deposit amount was sent, minimum allowed is 1page",
		},
		{
			name:          "ok",
			send:          std.Coins{{"page", 10}},
			borrowingDays: 15,
		},
	}

	for i, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			var (
				wantBalance, sendAmount uint64

				lender   = testhelpers.TestAddress(fmt.Sprintf("lend/lender%d", i))
				borrower = testhelpers.TestAddress(fmt.Sprintf("lend/borrower%d", i))
				bookID   = createBook(t, lender, "The Hitchhiker's Guide to the Galaxy")
			)

			mint(t, lender, 100)

			if len(tc.send) == 1 {
				sendAmount = uint64(tc.send[0].Amount)
				wantBalance = page.BalanceOf(lender) - sendAmount
			}

			std.TestSetOrigCaller(lender)
			std.TestSetOrigSend(tc.send, nil)

			// Act
			reason := testhelpers.HandlePanic(t, func() {
				contract.Lend(bookID, borrower, tc.borrowingDays)
			})

			// Assert
			if tc.err != "" {
				testhelpers.AssertPanicReason(t, tc.err, reason)
			} else {
				if reason != "" {
					t.Fatalf("expected no error, got: '%s'", reason)
				}

				if v := library.GetBorrower(bookID); v != pkgAddr {
					t.Errorf("expected lender to be pkg address '%s', got: '%s'", pkgAddr, v)
				}

				if v := page.BalanceOf(pkgAddr); v != sendAmount {
					t.Errorf("expected lender balance to be %dpage, got: %dpage", sendAmount, v)
				}

				if v := page.BalanceOf(lender); v != wantBalance {
					t.Errorf("expected lender balance to be %dpage, got: %dpage", wantBalance, v)
				}
			}
		})
	}
}

func mint(t *testing.T, addr std.Address, amount uint64) {
	t.Helper()

	std.TestSetOrigCaller(page.GetAdmin())

	reason := testhelpers.HandlePanic(t, func() {
		page.Mint(addr, amount)
	})
	if reason != "" {
		t.Error(reason)
	}
}

func createBook(t *testing.T, owner std.Address, title string) book.ID {
	std.TestSetOrigCaller(owner)
	return book.ID(library.Add(title))
}
