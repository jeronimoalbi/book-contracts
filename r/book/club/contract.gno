package club

import (
	"std"

	"gno.land/p/demo/avl"
	"gno.land/r/book/collection"
)

var agreements avl.Tree // collection.BookID -> *Agreement

// IsBorrowed checks if a book is currently borrowed.
func IsBorrowed(id collection.BookID) bool {
	return agreements.Has(id.String())
}

// Lend allows book owners to lend a book to a borrower for a period of time.
// Both the lender and the borrower must transfer a deposit which will be returned
// to each one when the book is returned to its owner.
func Lend(id collection.BookID, borrower std.Address, days uint64, deposit int64) {
	std.AssertOriginCall()
	assertBookIsAvailable(id)

	// TODO: Get the sent amount instead of automatically transfering to contract address ?
	//       (Same for Borrow)

	// Agreement deposit from the book lender
	banker := std.GetBanker(std.BankerTypeOrigSend)
	pkgAddr := std.GetOrigPkgAddr()
	lender := std.GetOrigCaller()
	coin := std.Coin{"ugnot", deposit} // TODO: Use "page" token
	banker.SendCoins(lender, pkgAddr, std.Coins{coin})

	// Create the book lend agreement
	agreement := NewAgreement(lender, borrower, days, deposit)
	agreements.Set(id.String(), agreement)

	// Lend the book to this contract
	collection.Lend(id, pkgAddr)
}

// Borrow allows book borrowers to borrow a book that was previously lent to them.
// At this point is when the borrower deposits the agreed amount for borrowing the book.
func Borrow(id collection.BookID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(id)
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
	coin := std.Coin{"ugnot", agreement.deposit} // TODO: Use "page" token
	banker.SendCoins(borrower, pkgAddr, std.Coins{coin})

	// Borrow the book
	if err := agreement.Borrow(); err != nil {
		panic(err)
	}
}

// Returns allows book borrowers to return a borrowed book.
func Return(id collection.BookID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(id)
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

// Receive allows book lenders to receive a lent book.
func Receive(id collection.BookID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(id)
	if !found || !agreement.IsBorrowed() {
		panic("book is not lent")
	}

	lender := std.GetOrigCaller()
	if agreement.Lender() != lender {
		panic("you are not the book owner")
	}

	// Close the agreement and return the book to the owner's collection
	agreements.Remove(id.String())
	collection.Return(id)

	// Return the deposit amounts to the lender and the borrower
	pkgAddr := std.GetOrigPkgAddr()
	refund := std.Coin{"ugnot", agreement.DepositAmount()} // TODO: Use "page" token
	banker := std.GetBanker(std.BankerTypeRealmSend)
	banker.SendCoins(pkgAddr, agreement.Lender(), std.Coins{refund})
	banker.SendCoins(pkgAddr, agreement.Borrower(), std.Coins{refund})
}

// ClaimDeposits allows book owners to claim the total agreement deposit after agreement expiration.
// Book is transfered to the borrowers's collection during this process making the borrower the
// current owner of the book.
// The claimed deposit includes both the lender and borrower deposit amounts.
func ClaimDeposits(id collection.BookID) {
	std.AssertOriginCall()

	agreement, found := getAgreement(id)
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
	collection.Transfer(id, agreement.Borrower())

	// Transfer the total amount deposited in the agreement to the lender
	pkgAddr := std.GetOrigPkgAddr()
	deposit := std.Coin{"ugnot", agreement.TotalAmount()} // TODO: Use "page" token
	banker := std.GetBanker(std.BankerTypeRealmSend)
	banker.SendCoins(pkgAddr, lender, std.Coins{deposit})
}

// GetLender returns the book owner's address.
func GetLender(id collection.BookID) string {
	agreement, found := getAgreement(id)
	if !found || !agreement.IsBorrowed() {
		panic("book is not lent")
	}

	return agreement.lender.String()
}

// GetBorrower returns the book borrower's address.
func GetBorrower(id collection.BookID) string {
	agreement, found := getAgreement(id)
	if !found || !agreement.IsBorrowed() {
		panic("book is not borrowed")
	}

	return agreement.borrower.String()
}

func getAgreement(id collection.BookID) (*Agreement, bool) {
	v, found := agreements.Get(id.String())
	if !found {
		return nil, false
	}

	return v.(*Agreement), true
}

func assertBookIsAvailable(id collection.BookID) {
	if IsBorrowed(id) || !collection.CheckAvailable(id) {
		panic("books is already borrowed")
	}
}
