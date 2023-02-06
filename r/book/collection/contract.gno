package collection

import (
	"std"

	"gno.land/p/demo/avl"
)

var (
	bookCtr            uint64
	collectionCtr      uint64
	bookCollections    avl.Tree // ID -> *Collection
	collectionsByOwner avl.Tree // std.Address(owner) -> ID
	lentBooks          avl.Tree // BookID -> std.Address(borrower)
)

// Add adds a new book to current account's collection.
func Add(title string) uint64 {
	owner := std.GetOrigCaller()
	book := NewBook(genBookID(), title)
	addBookToOwnerCollection(owner, book)
	return uint64(book.ID())
}

// Burn removes a book from current account's collection.
// This is a one way operation, once a book is burned it can't be recovered.
func Burn(bID BookID) {
	owner := std.GetOrigCaller()
	collection, found := getCollectionByOwner(owner)
	if !found {
		panic("book collection is empty")
	}

	if _, found = collection.Remove(bID); !found {
		panic("book not found")
	}
}

// Transfer a book from current account's collection to a different account.
func Transfer(bID BookID, to std.Address) {
	assertBookIsAvailable(bID)

	owner := std.GetOrigCaller()
	if owner == to {
		panic("transfer to the current owner is not allowed")
	}

	collection, found := getCollectionByOwner(owner)
	if !found {
		panic("book collection is empty")
	}

	book, found := collection.Remove(bID)
	if !found {
		panic("book not found")
	}

	addBookToOwnerCollection(to, book)
}

// CheckAvailable checks if a book can be lent.
func CheckAvailable(bID BookID) bool {
	return !lentBooks.Has(bID.String())
}

// Lend lends a book from current account's collection.
func Lend(bID BookID, to std.Address) {
	assertBookIsAvailable(bID)

	owner := std.GetOrigCaller()
	collection, found := getCollectionByOwner(owner)
	if !found {
		panic("book collection is empty")
	}

	if !collection.Has(bID) {
		panic("you don't own the book")
	}

	lentBooks.Set(bID.String(), to)
}

// Return returns a book to its owner's collection.
func Return(bID BookID) {
	borrower, found := getBorrower(bID)
	if !found {
		panic("book is not lent")
	}

	if borrower != std.GetOrigCaller() {
		panic("book can only be returned by the borrower")
	}

	lentBooks.Remove(bID.String())
}

// GetBorrower returns borrower's address.
func GetBorrower(bID BookID) string {
	borrower, found := getBorrower(bID)
	if !found {
		panic("book is not lent")
	}

	return borrower.String()
}

func genCollectionID() ID {
	collectionCtr++
	return ID(collectionCtr)
}

func genBookID() BookID {
	bookCtr++
	return BookID(bookCtr)
}

func getCollection(cID ID) (*Collection, bool) {
	v, found := bookCollections.Get(cID.String())
	if !found {
		return nil, false
	}

	return v.(*Collection), true
}

func getCollectionByOwner(owner std.Address) (*Collection, bool) {
	v, found := collectionsByOwner.Get(owner.String())
	if !found {
		return nil, false
	}

	return getCollection(v.(ID))
}

func getBorrower(bID BookID) (std.Address, bool) {
	v, found := lentBooks.Get(bID.String())
	if !found {
		return std.Address(""), false
	}

	return std.Address(v.(string)), true
}

func addBookToOwnerCollection(owner std.Address, book *Book) {
	collection, exists := getCollectionByOwner(owner)
	if !exists {
		collection = New(genCollectionID())
	}

	collection.Add(book)

	if !exists {
		cID := collection.ID().String()
		bookCollections.Set(cID, collection)
		collectionsByOwner.Set(owner.String(), cID)
	}
}

func assertBookIsAvailable(bID BookID) {
	if !CheckAvailable(bID) {
		panic("book is lent")
	}
}
