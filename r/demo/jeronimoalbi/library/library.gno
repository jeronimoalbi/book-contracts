package library

import (
	"errors"
	"std"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/jeronimoalbi/book"
)

// New creates a new library.
func New() Library {
	return Library{
		collections: avl.NewTree(),
		lentBooks:   avl.NewTree(),
	}
}

// Library stores book collections for different addresses.
// It also allows to keep track of books that has been lent to other address.
type Library struct {
	collections *avl.Tree // std.Address(owner) -> *book.Collection
	lentBooks   *avl.Tree // Book ID -> std.Address(borrower)
}

// Size returns the number of book collections in the library.
func (self Library) Size() int {
	return self.collections.Size()
}

// HasCollection checks if an address has a book collection.
func (self Library) HasCollection(owner std.Address) bool {
	_, found := self.collections.Get(owner.String())
	return found
}

// GetCollection returns a book collection for an address.
func (self Library) GetCollection(owner std.Address) (*book.Collection, bool) {
	if v, found := self.collections.Get(owner.String()); found {
		return v.(*book.Collection), true
	}
	return nil, false
}

// AddCollection adds a book collection to an address.
func (self Library) AddCollection(owner std.Address, c *book.Collection) error {
	if self.HasCollection(owner) {
		return errors.New("owner already have a book collection")
	}

	self.collections.Set(owner.String(), c)
	return nil
}

// IsLent checks if a book is currently lent.
func (self Library) IsLent(bookID book.ID) bool {
	return self.lentBooks.Has(bookID.String())
}

// Lend lends a book to a borrower address.
func (self Library) Lend(owner, borrower std.Address, bookID book.ID) error {
	collection, found := self.GetCollection(owner)
	if !found {
		return errors.New("lender has no books")
	}

	if !collection.Has(bookID) {
		return errors.New("lender doesn't own the book")
	}

	self.lentBooks.Set(bookID.String(), borrower.String())
	return nil
}

// GetBorrower returns the address that currently borrowed a book.
func (self Library) GetBorrower(bookID book.ID) (std.Address, bool) {
	v, found := self.lentBooks.Get(bookID.String())
	if found {
		return std.Address(v.(string)), true
	}
	return std.Address(""), false
}

// Return returns a borrowed book to it's owner.
func (self Library) Return(bookID book.ID) error {
	borrower, found := self.GetBorrower(bookID)
	if !found {
		return errors.New("book is not lent")
	}

	if borrower != std.GetOrigCaller() {
		return errors.New("book can only be returned by the borrower")
	}

	self.lentBooks.Remove(bookID.String())
	return nil
}

// GetBook returns a book that belongs to an owner account.
func (self Library) GetBook(owner std.Address, bookID book.ID) (*book.Book, bool) {
	collection, found := self.GetCollection(owner)
	if found {
		return collection.Get(bookID)
	}
	return nil, false
}
