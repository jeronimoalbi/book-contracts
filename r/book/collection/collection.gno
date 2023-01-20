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
	collectionsByOwner avl.Tree // std.Address -> book.CollectionID
)

func genCollectionID() book.CollectionID {
	collectionCtr++
	return book.CollectionID(collectionCtr)
}

func genBookID() book.ID {
	bookCtr++
	return book.ID(bookCtr)
}

func getCollection(id book.CollectionID) (*book.Collection, bool) {
	v, found := bookCollections.Get(id.String())
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

func addBookToOwnerCollection(owner std.Address, book *book.Book) {
	collection, exists := getCollectionByOwner(owner)
	if !exists {
		collection = book.NewCollection(genCollectionID())
	}

	collection.Add(book)

	if !exists {
		cID := collection.ID().String()
		bookCollections.Set(cID, collection)
		collectionsByOwner.Set(owner.String(), cID)
	}
}

// Add adds a new book to current account's collection.
func Add(title string) {
	book := book.NewBook(genBookID(), title)
	addBookToOwnerCollection(book)
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
