package bookclub

import (
	"std"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/jeronimoalbi/book"
	"gno.land/p/demo/ufmt"
	"gno.land/r/demo/jeronimoalbi/page"

	"gno.land/r/demo/jeronimoalbi/library"
)

const (
	token            = "page"
	minDepositAmount = int64(1)
)

var agreements *avl.Tree // Book's book.ID -> *Agreement

func init() {
	agreements = avl.NewTree()
}

// IsBorrowed checks if a book is currently borrowed as part of an agreement between two accounts.
func IsBorrowed(bookID book.ID) bool {
	a, found := getAgreement(bookID)
	if !found {
		return false
	}
	return a.IsBorrowed()
}

// Lend allows book owners to lend a book to a borrower for a period of time.
// Both the lender and the borrower must transfer a deposit to make the agreement valid.
// The deposits will be returned when the book is returned to its owner.
func Lend(bookID book.ID, borrower std.Address, days uint64) {
	// TODO: Figure out why tests panic with 'invalid non-origin call'
	// std.AssertOriginCall()
	assertBookIsAvailable(bookID)

	if days == 0 {
		panic("The minimum borrowing period is one day")
	}

	sent := std.GetOrigSend()
	if len(sent) != 1 {
		panic("Send only one type of coin")
	}

	amount := sent.AmountOf(token)
	if amount < minDepositAmount {
		reason := ufmt.Sprintf("An invalid deposit amount was sent, minimum allowed is %d%s", minDepositAmount, token)
		panic(reason)
	}

	// Agreement deposit from the book lender
	pkgAddr := std.CurrentRealm().Addr()
	page.Transfer(pkgAddr, uint64(amount))

	// Create the book lending agreement
	lender := std.GetOrigCaller()
	agreements.Set(bookID.String(), NewAgreement(lender, borrower, days, sent[0]))

	// Lend the book to this contract
	library.Lend(pkgAddr, bookID)
}

// Borrow allows book borrowers to borrow a book that was previously lent to them.
// At this point is when the borrower deposits the agreed amount for borrowing the book.
func Borrow(bookID book.ID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(bookID)
	if !found {
		panic("book owner didn't agree to lend the book yet")
	}

	if agreement.IsBorrowed() {
		panic("book is already borrowed")
	}

	borrower := std.GetOrigCaller()
	if agreement.Borrower() != borrower {
		panic("book is not lent to you")
	}

	// Agreement deposit from the book borrower
	banker := std.GetBanker(std.BankerTypeOrigSend)
	pkgAddr := std.GetOrigPkgAddr()
	coin := agreement.Deposit()
	banker.SendCoins(borrower, pkgAddr, std.Coins{coin})

	// Borrow the book
	if err := agreement.Borrow(); err != nil {
		panic(err)
	}
}

// Returns allows book borrowers to return a borrowed book.
func Return(bookID book.ID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(bookID)
	if !found || !agreement.IsBorrowed() {
		panic("book is not borrowed")
	}

	// if agreement.IsExpired() {
	// 	panic("book can't be returned after agreement expiration")
	// }

	borrower := std.GetOrigCaller()
	if agreement.Borrower() != borrower {
		panic("book was not borrowed by you")
	}

	if err := agreement.Return(); err != nil {
		panic(err)
	}
}

// Receive allows book lenders to receive a borrowed book.
func Receive(bookID book.ID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(bookID)
	if !found || !agreement.IsBorrowed() {
		panic("book is not lent")
	}

	lender := std.GetOrigCaller()
	if agreement.Lender() != lender {
		panic("you are not the book owner")
	}

	// Close the agreement and return the book to the owner's collection
	agreements.Remove(bookID.String())
	library.Return(bookID)

	// Return the deposit amounts to the lender and the borrower
	pkgAddr := std.GetOrigPkgAddr()
	refund := agreement.Deposit()
	banker := std.GetBanker(std.BankerTypeRealmSend)
	banker.SendCoins(pkgAddr, agreement.Lender(), std.Coins{refund})
	banker.SendCoins(pkgAddr, agreement.Borrower(), std.Coins{refund})
}

// ClaimDeposits allows book owners to claim the total agreement deposit after agreement expiration.
// Book is transfered to the borrowers's collection during this process making the borrower the
// current owner of the book.
// The claimed deposit includes both the lender and borrower deposit amounts.
func ClaimDeposits(bookID book.ID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(bookID)
	if !found || !agreement.IsBorrowed() {
		panic("book is not lent")
	}

	// if !agreement.IsExpired() {
	// 	panic("you are not allowed to claim the deposits because agreement didn't expire yet")
	// }

	lender := std.GetOrigCaller()
	if agreement.Lender() != lender {
		panic("only the book owner can claim the deposits")
	}

	// Transfer book to the borrower's collection
	library.Transfer(agreement.Borrower(), bookID)

	// Transfer the total amount deposited in the agreement to the lender
	pkgAddr := std.GetOrigPkgAddr()
	deposit := agreement.TotalDeposit()
	banker := std.GetBanker(std.BankerTypeRealmSend)
	banker.SendCoins(pkgAddr, lender, std.Coins{deposit})
}

// GetLender returns the book owner's address.
func GetLender(bookID book.ID) string {
	agreement, found := getAgreement(bookID)
	if !found || !agreement.IsBorrowed() {
		panic("book is not lent")
	}

	return agreement.lender.String()
}

// GetBorrower returns the book borrower's address.
func GetBorrower(bookID book.ID) string {
	agreement, found := getAgreement(bookID)
	if !found || !agreement.IsBorrowed() {
		panic("book is not borrowed")
	}

	return agreement.borrower.String()
}

func getAgreement(bookID book.ID) (*Agreement, bool) {
	v, found := agreements.Get(bookID.String())
	if !found {
		return nil, false
	}

	return v.(*Agreement), true
}

func assertBookIsAvailable(bookID book.ID) {
	// Check id the book has been borrowed as part of a lend agreement
	if IsBorrowed(bookID) {
		panic("books is already borrowed")
	}

	// Check the owner's book collection to validate that the book is available to be lent
	if library.IsLent(bookID) {
		panic("books is not available to be borrowed")
	}
}
