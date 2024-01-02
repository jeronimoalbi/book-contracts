package bookclub

import (
	"errors"
	"std"
	"time"
)

// NewAgreement creates a new lending agreement.
func NewAgreement(lender, borrower std.Address, days uint64, deposit std.Coin) *Agreement {
	return &Agreement{
		lender:   lender,
		borrower: borrower,
		days:     days,
		deposit:  deposit,
	}
}

// Agreement defines a lending agreement between two accounts.
// It specifies two accounts for the entities that agree on a lending period and the
// amount that each of the entities must deposit for the agreement to be valid.
type Agreement struct {
	lender       std.Address
	borrower     std.Address
	days         uint64
	deposit      std.Coin
	borrowedAt   time.Time
	bookReturned bool
}

// Lender returns the lender account address.
func (a Agreement) Lender() std.Address {
	return a.lender
}

// Borrower returns the borrower account address.
func (a Agreement) Borrower() std.Address {
	return a.borrower
}

// Borrow initializes the borrowing date the makes the agreement valid.
// The borrowing date is initialized with the current block time.
func (a *Agreement) Borrow() error {
	if a.IsBorrowed() {
		return errors.New("book is borrowed")
	}

	a.borrowedAt = time.Now()
	return nil
}

// Days returns the number of days that the agreement is valid for.
func (a Agreement) Days() uint64 {
	return a.days
}

// Deposit returns the deposit amount that each account must deposit to confirm the agreement.
func (a Agreement) Deposit() std.Coin {
	return a.deposit
}

// BorrowedAt returns the block time that the agreement started.
func (a Agreement) BorrowedAt() time.Time {
	return a.borrowedAt
}

// TotalDeposit returns the total amount that should be deposited for the agreement to be valid.
// The total amount is the sum of the lender and borrower deposits.
func (a Agreement) TotalDeposit() std.Coin {
	return std.Coin{
		Denom:  a.deposit.Denom,
		Amount: a.deposit.Amount * 2,
	}
}

// Extend extends the validity period of the agreement.
func (a *Agreement) Extend(days uint64) {
	a.days = a.days + days
}

// Return marks the agreement as fulfilled.
// This method should be called by the borrower when returning the lended book.
func (a *Agreement) Return() error {
	if !a.IsBorrowed() {
		return errors.New("book is not borrowed")
	}

	a.bookReturned = true
	return nil
}

// IsBorrowed checks if the agreement started.
func (a Agreement) IsBorrowed() bool {
	return !a.BorrowedAt().IsZero()
}

// IsExpired checks if the agreement period is expired.
func (a Agreement) IsExpired() bool {
	if !a.IsBorrowed() {
		return false
	}

	daysSinceBorrowed := uint64(time.Now().Sub(a.borrowedAt).Hours() / 24)
	return daysSinceBorrowed > a.days
}

// IsBookReturned checks if the agreement is fulfilled.
func (a Agreement) IsBookReturned() bool {
	return a.bookReturned
}
