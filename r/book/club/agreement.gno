package club

import (
	"errors"
	"std"
	"time"
)

func NewAgreement(lender, borrower std.Address, days uint64, deposit int64) *Agreement {
	// TODO: Check that the deposit doesn't exceed a max limit and if so use a reasonable default
	return &Agreement{
		lender:   lender,
		borrower: borrower,
		days:     days,
		deposit:  deposit,
	}
}

type Agreement struct {
	lender       std.Address
	borrower     std.Address
	days         uint64
	deposit      int64
	borrowedAt   time.Time
	bookReturned bool
}

func (a Agreement) Lender() std.Address {
	return a.lender
}

func (a Agreement) Borrower() std.Address {
	return a.borrower
}

func (a *Agreement) Borrow() error {
	if a.IsBorrowed() {
		return errors.New("book is borrowed")
	}

	a.borrowedAt = time.Now()
	return nil
}

func (a Agreement) Days() uint64 {
	return a.days
}

func (a Agreement) DepositAmount() int64 {
	return a.deposit
}

func (a Agreement) TotalAmount() int64 {
	return a.deposit * 2
}

func (a *Agreement) Return() error {
	if !a.IsBorrowed() {
		return errors.New("book is not borrowed")
	}

	a.bookReturned = true
}

func (a Agreement) BorrowedAt() time.Time {
	return a.borrowedAt
}

func (a Agreement) IsBorrowed() bool {
	return !a.BorrowedAt().IsZero()
}

func (a Agreement) IsExpired() bool {
	if !a.IsBorrowed() {
		return false
	}

	daysSinceBorrowed := uint64(a.borrowedAt.Sub(time.Now()).Hours() / 24)
	return daysSinceBorrowed <= a.days
}

func (a Agreement) IsBookReturned() bool {
	return a.bookReturned
}
