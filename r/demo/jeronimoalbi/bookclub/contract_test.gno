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

	// TODO: Handle book already borrowed case
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
			name:          "no deposit",
			borrowingDays: 1,
			err:           "A deposit is required",
		},
		{
			name:          "send invalid deposit",
			send:          std.Coins{{"ugnot", 42}},
			borrowingDays: 1,
			err:           "The minimum deposit is 1page",
		},
		{
			name:          "min deposit",
			send:          std.Coins{{"page", 0}},
			borrowingDays: 1,
			err:           "The minimum deposit is 1page",
		},
		{
			name:          "ok",
			send:          std.Coins{{"page", 10}, {"ugnot", 42}},
			borrowingDays: 15,
		},
	}

	for i, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			var (
				wantBalance, sentAmount uint64

				lender   = testhelpers.TestAddress(fmt.Sprintf("lend/lender%d", i))
				borrower = testhelpers.TestAddress(fmt.Sprintf("lend/borrower%d", i))
				bookID   = createBook(t, lender, "The Hitchhiker's Guide to the Galaxy")
			)

			mint(t, lender, 100)

			if tc.send != nil {
				sentAmount = uint64(tc.send.AmountOf("page"))
				wantBalance = page.BalanceOf(lender) - sentAmount
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
					t.Errorf("expected lender to be realm address '%s', got: '%s'", pkgAddr, v)
				}

				if v := page.BalanceOf(pkgAddr); v != sentAmount {
					t.Errorf("expected realm balance to be %dpage, got: %dpage", sentAmount, v)
				}

				if v := page.BalanceOf(lender); v != wantBalance {
					t.Errorf("expected lender balance to be %dpage, got: %dpage", wantBalance, v)
				}
			}
		})
	}
}

func TestBorrow(t *testing.T) {
	pkgAddr := std.DerivePkgAddr("gno.land/r/demo/jeronimoalbi/bookclub")
	lender := testhelpers.TestAddress(fmt.Sprintf("borrow/lender"))

	mint(t, lender, 100)

	// TODO: Add other cases
	cases := []struct {
		name  string
		send  std.Coins
		setup func(*testing.T, std.Address) book.ID
		err   string
	}{
		{
			name: "book not lent",
			send: std.Coins{{"page", 1}},
			setup: func(t *testing.T, borrower std.Address) book.ID {
				return 42
			},
			err: "Book owner didn't agree to lend the book yet",
		},
		{
			name: "book lent to other",
			send: std.Coins{{"page", 1}},
			setup: func(t *testing.T, _ std.Address) book.ID {
				borrower := testhelpers.TestAddress("borrow/foo/borrower")
				bookID := createBook(t, lender, "The Hitchhiker's Guide to the Galaxy")
				lendBook(t, bookID, lender, borrower)
				return bookID
			},
			err: "Book is not lent to you",
		},
		{
			name: "book already borrowed",
			send: std.Coins{{"page", 1}},
			setup: func(t *testing.T, _ std.Address) book.ID {
				borrower := testhelpers.TestAddress("borrow/foo/borrower2")
				bookID := createBook(t, lender, "The Hitchhiker's Guide to the Galaxy")
				lendBook(t, bookID, lender, borrower)
				mint(t, borrower, 1)
				borrowBook(t, bookID, borrower)
				return bookID
			},
			err: "Book is already borrowed",
		},
		{
			name: "ok",
			send: std.Coins{{"page", 1}},
			setup: func(t *testing.T, borrower std.Address) book.ID {
				bookID := createBook(t, lender, "The Hitchhiker's Guide to the Galaxy")
				lendBook(t, bookID, lender, borrower)
				return bookID
			},
		},
	}

	for i, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			var (
				wantBalance, realmAmount uint64

				borrower = testhelpers.TestAddress(fmt.Sprintf("borrow/borrower%d", i))
				bookID   = tc.setup(t, borrower)
			)

			mint(t, borrower, 10)

			if tc.send != nil {
				sentAmount := uint64(tc.send.AmountOf("page"))
				realmAmount = page.BalanceOf(pkgAddr) + sentAmount // Realm amount is lender+borrower deposits
				wantBalance = page.BalanceOf(borrower) - sentAmount
			}

			std.TestSetOrigCaller(borrower)
			std.TestSetOrigSend(tc.send, nil)

			// Act
			reason := testhelpers.HandlePanic(t, func() {
				contract.Borrow(bookID)
			})

			// Assert
			if tc.err != "" {
				testhelpers.AssertPanicReason(t, tc.err, reason)
			} else {
				if reason != "" {
					t.Fatalf("expected no error, got: '%s'", reason)
				}

				if v := page.BalanceOf(pkgAddr); v != realmAmount {
					t.Errorf("expected realm balance to be %dpage, got: %dpage", realmAmount, v)
				}

				if v := page.BalanceOf(borrower); v != wantBalance {
					t.Errorf("expected borrower balance to be %dpage, got: %dpage", wantBalance, v)
				}
			}
		})
	}
}

func TestReturn(t *testing.T) {
	// TODO: Implement
}

func TestReceive(t *testing.T) {
	// TODO: Implement
}

func TestClaimDeposits(t *testing.T) {
	// TODO: Implement
}

func TestGetLender(t *testing.T) {
	// TODO: Implement
}

func TestGetBorrower(t *testing.T) {
	// TODO: Implement
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

func lendBook(t *testing.T, id book.ID, lender, borrower std.Address) {
	t.Helper()

	std.TestSetOrigCaller(lender)
	std.TestSetOrigSend(std.Coins{std.Coin{"page", 1}}, nil)

	reason := testhelpers.HandlePanic(t, func() {
		contract.Lend(id, borrower, 10)
	})
	if reason != "" {
		t.Error(reason)
	}
}

func borrowBook(t *testing.T, id book.ID, borrower std.Address) {
	t.Helper()

	std.TestSetOrigCaller(borrower)
	std.TestSetOrigSend(std.Coins{std.Coin{"page", 1}}, nil)

	reason := testhelpers.HandlePanic(t, func() {
		contract.Borrow(id)
	})
	if reason != "" {
		t.Error(reason)
	}
}
