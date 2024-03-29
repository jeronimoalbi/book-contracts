package library

import (
	"std"

	"gno.land/p/demo/jeronimoalbi/book"
)

var (
	bookCtr uint64
	library Library
)

func init() {
	library = New()
}

// Add adds a new book to current account's collection.
func Add(title string) uint64 {
	owner := std.GetOrigCaller()
	collection, found := library.GetCollection(owner)
	if !found {
		collection = book.NewCollection()
		library.AddCollection(owner, collection)
	}

	newBook := book.New(genBookID(), title)
	collection.Add(newBook)

	return uint64(newBook.ID())
}

// Burn removes a book from current account's collection.
// This is a one way operation, once a book is burned it can't be recovered.
func Burn(id book.ID) {
	owner := std.GetOrigCaller()
	collection, found := library.GetCollection(owner)
	if !found {
		panic("book collection is empty")
	}

	if _, found = collection.Remove(id); !found {
		panic("book not found")
	}
}

// Transfer a book from current account's collection to a different account.
func Transfer(newOwner std.Address, id book.ID) {
	assertBookIsNotLent(id)

	owner := std.GetOrigCaller()
	if owner == newOwner {
		panic("transfer to the current owner is not allowed")
	}

	collection, found := library.GetCollection(owner)
	if !found {
		panic("book collection is empty")
	}

	currentBook, found := collection.Remove(id)
	if !found {
		panic("book not found")
	}

	collection, found = library.GetCollection(newOwner)
	if !found {
		collection = book.NewCollection()
		library.AddCollection(newOwner, collection)
	}

	collection.Add(currentBook)
}

// Lend lends a book from current account's collection.
func Lend(borrower std.Address, id book.ID) {
	assertBookIsNotLent(id)

	owner := std.GetOrigCaller()
	if err := library.Lend(owner, borrower, id); err != nil {
		panic(err)
	}
}

// IsLent checks if a book is currently lent.
func IsLent(id book.ID) bool {
	return library.IsLent(id)
}

// Return returns a book to its owner's collection.
func Return(id book.ID) {
	if err := library.Return(id); err != nil {
		panic(err)
	}
}

// GetBorrower returns borrower's address.
func GetBorrower(id book.ID) string {
	borrower, found := library.GetBorrower(id)
	if !found {
		panic("book is not lent")
	}
	return borrower.String()
}

// GetBook returns a book that belongs to an owner account.
func GetBook(owner std.Address, id book.ID) (book.Book, bool) {
	b, found := library.GetBook(owner, id)
	if !found {
		return book.Book{}, false
	}
	return *b, true
}

func genBookID() book.ID {
	bookCtr++
	return book.ID(bookCtr)
}

func assertBookIsNotLent(id book.ID) {
	if library.IsLent(id) {
		panic("book is lent")
	}
}
