package collection

import (
	"errors"
	"std"

	"gno.land/p/demo/avl"
)

type Library struct {
	collections avl.Tree // std.Address(owner) -> *Collection
	lentBooks   avl.Tree // BookID -> std.Address(borrower)
}

func (self Library) HasCollection(owner std.Address) bool {
	_, found := self.collections.Get(owner.String())
	return found
}

func (self Library) GetCollection(owner std.Address) (*Collection, bool) {
	if v, found := self.collections.Get(owner.String()); found {
		return v.(*Collection), true
	}
	return nil, false
}

func (self Library) AddCollection(owner std.Address, c *Collection) error {
	if self.HasCollection(owner) {
		return errors.New("owner already have a book collection")
	}

	self.collections.Set(owner, c)
	return nil
}

func (self Library) IsBookAvailable(bookID BookID) bool {
	return !self.lentBooks.Has(bookID.String())
}

func (self Library) Lend(owner, borrower std.Address, bookID BookID) error {
	collection, found := self.GetCollection(owner)
	if !found {
		return errors.New("owner has no books")
	}

	if !collection.Has(bookID) {
		return errors.New("lender doesn't own the book")
	}

	self.lentBooks.Set(bookID.String(), borrower)
	return nil
}

func (self Library) GetBorrower(bookID BookID) (std.Address, bool) {
	v, found := self.lentBooks.Get(bookID.String())
	if found {
		return std.Address(v.(string)), true
	}
	return std.Address(""), false
}

func (self Library) Return(bookID BookID) error {
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
