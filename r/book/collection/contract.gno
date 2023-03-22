package collection

import "std"

var (
	bookCtr uint64
	library Library
)

func init() {
	library = Library{}
}

// Add adds a new book to current account's collection.
func Add(title string) uint64 {
	owner := std.GetOrigCaller()
	collection, found := library.GetCollection(owner)
	if !found {
		collection = &Collection{}
		library.Add(owner, collection)
	}

	book := NewBook(genBookID(), title)
	collection.Add(book)

	return uint64(book.ID())
}

// Burn removes a book from current account's collection.
// This is a one way operation, once a book is burned it can't be recovered.
func Burn(bookID BookID) {
	owner := std.GetOrigCaller()
	collection, found := library.GetCollection(owner)
	if !found {
		panic("book collection is empty")
	}

	if _, found = collection.Remove(bookID); !found {
		panic("book not found")
	}
}

// Transfer a book from current account's collection to a different account.
func Transfer(newOwner std.Address, bookID BookID) {
	assertBookIsAvailable(bookID)

	owner := std.GetOrigCaller()
	if owner == newOwner {
		panic("transfer to the current owner is not allowed")
	}

	collection, found := library.GetCollection(owner)
	if !found {
		panic("book collection is empty")
	}

	book, found := collection.Remove(bookID)
	if !found {
		panic("book not found")
	}

	collection, found = library.GetCollection(newOwner)
	if !found {
		collection = &Collection{}
		library.Add(newOwner, collection)
	}

	collections.Add(book)
}

// Lend lends a book from current account's collection.
func Lend(borrower std.Address, bookID BookID) {
	assertBookIsAvailable(bookID)

	owner := std.GetOrigCaller()
	if err := library.Lend(owner, borrower, bookID); err != nil {
		panic(err)
	}
}

// Return returns a book to its owner's collection.
func Return(bookID BookID) {
	if err := Library.Return(bookID); err != nil {
		panic(err)
	}
}

// GetBorrower returns borrower's address.
func GetBorrower(bookID BookID) string {
	borrower, found := library.GetBorrower(bookID)
	if !found {
		panic("book is not lent")
	}
	return borrower.String()
}

func genBookID() BookID {
	bookCtr++
	return BookID(bookCtr)
}

func assertBookIsAvailable(bookID BookID) {
	if !library.IsBookAvailable(bookID) {
		panic("book is lent")
	}
}
