package bookclub

import (
	"std"
	"testing"
	"time"

	"gno.land/p/demo/testutils"
)

func TestNewAgreement(t *testing.T) {
	// Arrange
	lender := testutils.TestAddress("lender")
	borrower := testutils.TestAddress("borrower")
	days := uint64(15)
	deposit := std.Coin{
		Denom:  "ugnot",
		Amount: 100,
	}

	// Act
	agreement := NewAgreement(lender, borrower, days, deposit)

	// Assert
	if v := agreement.Lender(); v != lender {
		t.Errorf("expected lender '%s', got: '%s'", lender, v)
	}

	if v := agreement.Borrower(); v != borrower {
		t.Errorf("expected borrower '%s', got: '%s'", borrower, v)
	}

	if v := agreement.Days(); v != days {
		t.Errorf("expected days %d, got: %d", days, v)
	}

	if v := agreement.Deposit(); v != deposit {
		t.Errorf("expected deposit %v, got: %v", deposit, v)
	}

	if v := agreement.TotalDeposit(); v.Denom != deposit.Denom {
		t.Errorf("expected total deposit denom to be '%s', got: '%s'", deposit.Denom, v.Denom)
	}

	if v := agreement.TotalDeposit(); v.Amount != (deposit.Amount * 2) {
		t.Errorf("expected total deposit amount to be %d, got: %d", deposit.Amount*2, v.Amount)
	}

	if v := agreement.BorrowedAt(); !v.IsZero() {
		t.Errorf("expected borrow time to be zero, got: %s", v.String())
	}

	if agreement.IsBorrowed() {
		t.Error("expected is borrowed check to be false")
	}

	if agreement.IsExpired() {
		t.Error("expected is expired check to be false")
	}

	if agreement.IsBookReturned() {
		t.Error("expected is book returned check to be false")
	}
}

func TestAgreementBorrow(t *testing.T) {
	// Arrange
	lender := testutils.TestAddress("lender")
	borrower := testutils.TestAddress("borrower")
	agreement := NewAgreement(lender, borrower, 42, std.Coin{"ugnot", 100})

	// Act
	err := agreement.Borrow()

	// Assert
	if v := agreement.BorrowedAt(); v != time.Now() {
		t.Errorf("expected borrow time to be %s, got %s", time.Now().String(), v.String())
	}

	if err != nil {
		t.Errorf("expected no error, got: %v", err.Error())
	}

	if err := agreement.Borrow(); err == nil {
		t.Errorf("expected second borrow call to return 'book is borrowed', got: '%s'", err.Error())
	}

	if !agreement.IsBorrowed() {
		t.Error("expected is borrowed check to be true")
	}

	if agreement.IsExpired() {
		t.Error("expected is expired check to be false")
	}

	if agreement.IsBookReturned() {
		t.Error("expected is book returned check to be false")
	}
}

func TestAgreementReturn(t *testing.T) {
	// Arrange
	lender := testutils.TestAddress("lender")
	borrower := testutils.TestAddress("borrower")
	cases := []struct {
		name  string
		err   string
		setup func() *Agreement
	}{
		{
			name: "ok",
			setup: func() *Agreement {
				a := NewAgreement(lender, borrower, 42, std.Coin{"ugnot", 100})
				a.Borrow()
				return a
			},
		},
		{
			name: "not borrowed",
			err:  "book is not borrowed",
			setup: func() *Agreement {
				return NewAgreement(lender, borrower, 42, std.Coin{"ugnot", 100})
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			agreement := tc.setup()

			// Act
			err := agreement.Return()

			// Assert
			if tc.err != "" {
				if err == nil {
					t.Errorf("expected error '%s' to be returned", tc.err)
				} else if v := err.Error(); v != tc.err {
					t.Errorf("expected error '%s', got: '%v'", tc.err, err)
				}
			} else {
				if err != nil {
					t.Errorf("expected no error, got: '%s'", err.Error())
				}

				if !agreement.IsBorrowed() {
					t.Error("expected is borrowed check to be true")
				}

				if agreement.IsExpired() {
					t.Error("expected is expired check to be false")
				}

				if !agreement.IsBookReturned() {
					t.Error("expected is book returned check to be true")
				}
			}
		})
	}
}

func TestAgreementIsExpired(t *testing.T) {
	// Arrange
	lender := testutils.TestAddress("lender")
	borrower := testutils.TestAddress("borrower")
	days := uint64(42)
	agreement := NewAgreement(lender, borrower, days, std.Coin{"ugnot", 100})
	agreement.Borrow()

	agreement.borrowedAt = agreement.borrowedAt.AddDate(0, 0, int(-days-1)) // Right now there is no way to test set block time

	// Act
	expired := agreement.IsExpired()

	// Assert
	if !expired {
		t.Error("expected agreement to be expired")
	}
}
