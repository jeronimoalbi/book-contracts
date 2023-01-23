package collection

import (
	"std"
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/book" // NOTE: Whitelisted package prefix
)

var (
	bookCtr            uint64
	collectionCtr      uint64
	bookCollections    avl.Tree // book.CollectionID -> *book.Collection
	collectionsByOwner avl.Tree // std.Address(owner) -> book.CollectionID
	lentBooks          avl.Tree // book.ID -> std.Address(borrower)
)

// Add adds a new book to current account's collection.
func Add(title string) uint64 {
	book := book.NewBook(genBookID(), title)
	addBookToOwnerCollection(book)
	return book.ID()
}

// Burn removes a book from current account's collection.
// This is a one way operation, once a book is burned it can't be recovered.
func Burn(id book.ID) {
	owner := std.GetOrigCaller()
	collection, found := getCollectionByOwner(owner)
	if !found {
		panic("book collection is empty")
	}

	if _, found = collection.Remove(id); !found {
		panic("book not found")
	}
}

// Transfer a book from current account's collection to a different account.
func Transfer(id book.ID, to std.Address) {
	assertBookIsAvailable(id)

	owner := std.GetOrigCaller()
	if owner == to {
		panic("transfer to the current owner is not allowed")
	}

	collection, found := getCollectionByOwner(owner)
	if !found {
		panic("book collection is empty")
	}

	book, found := collection.Remove(id)
	if !found {
		panic("book not found")
	}

	addBookToOwnerCollection(to)
}

// CheckAvailable checks if a book has been lent.
func CheckAvailable(id book.ID) bool {
	return !lentBooks.Has(id.String())
}

// Lend lends a book from current account's collection.
func Lend(id book.ID, to std.Address) {
	assertBookIsAvailable(id)

	owner := std.GetOrigCaller()
	collection, found := getCollectionByOwner(owner)
	if !found {
		panic("book collection is empty")
	}

	if !collection.Has(id) {
		panic("book not found")
	}

	lentBooks.Set(id.String(), to)
}

// Return returns a book to its owner's collection.
func Return(id book.ID) {
	borrower, found := getBorrower(id)
	if !found {
		panic("book is not lent")
	}

	if borrower != std.GetOrigCaller() {
		panic("book can only be returned by the borrower")
	}

	lentBooks.Remove(id.String())
}

// Render renders a book collection.
func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case c == 1:
		id, err := strconv.Atoi(parts[0])
		if err != nil {
			return "Invalid collection ID"
		}

		cID := book.CollectionID(id)
		collection, found := getCollection(cID)
		if !found {
			return "Book collection is empty"
		}

		return collection.Render()
	default:
		return "Not Found"
	}
}

func genCollectionID() book.CollectionID {
	collectionCtr++
	return book.CollectionID(collectionCtr)
}

func genBookID() book.ID {
	bookCtr++
	return book.ID(bookCtr)
}

func getCollection(cid book.CollectionID) (*book.Collection, bool) {
	v, found := bookCollections.Get(cid.String())
	if !found {
		return nil, false
	}

	return v.(*book.Collection), true
}

func getCollectionByOwner(owner std.Address) (*book.Collection, bool) {
	v, found := collectionsByOwner.Get(owner.String())
	if !found {
		return nil, false
	}

	return getCollection(v.(book.CollectionID))
}

func getBorrower(id book.ID) (std.Address, bool) {
	v, found := lentBooks.Get(id.String())
	if !found {
		return std.Address(""), false
	}

	return std.Address(v.(string)), true
}

func addBookToOwnerCollection(owner std.Address, book *book.Book) {
	collection, exists := getCollectionByOwner(owner)
	if !exists {
		collection = book.NewCollection(genCollectionID())
	}

	collection.Add(book)

	if !exists {
		cid := collection.ID().String()
		bookCollections.Set(cid, collection)
		collectionsByOwner.Set(owner.String(), cid)
	}
}

func assertBookIsAvailable(id book.ID) {
	if !CheckAvailable(id) {
		panic("book is lent")
	}
}
