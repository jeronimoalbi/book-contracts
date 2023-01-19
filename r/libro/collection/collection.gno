package collection

import (
	"std"
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
	"gno.land/p/demo/libro" // NOTE: Whitelisted package prefix
)

var (
	bookCtr            uint64
	collectionCtr      uint64
	bookCollections    avl.Tree // libro.CollectionID -> *libro.Collection
	collectionsByOwner avl.Tree // std.Address -> libro.CollectionID
)

func genCollectionID() libro.CollectionID {
	collectionCtr++
	return libro.CollectionID(collectionCtr)
}

func genBookID() libro.BookID {
	bookCtr++
	return libro.BookID(bookCtr)
}

func getCollection(id libro.CollectionID) (*libro.Collection, bool) {
	c, found := bookCollections.Get(id.String())
	if !found {
		return nil, false
	}

	return c.(*libro.Collection), true
}

func getCollectionByOwner(owner std.Address) (*libro.Collection, bool) {
	id, found := collectionsByOwner.Get(owner.String())
	if !found {
		return nil, false
	}

	return getCollection(id.(libro.CollectionID))
}

func AddBook(title string) {
	owner := std.GetOrigCaller()
	collection, exists := getCollectionByOwner(owner)
	if !exists {
		collection = libro.NewCollection(genCollectionID())
	}

	book := libro.NewBook(genBookID(), title)
	collection.Add(book)

	if !exists {
		cID := collection.ID().String()
		bookCollections.Set(cID, collection)
		collectionsByOwner.Set(owner.String(), cID)
	}
}

func RemoveBook(id libro.BookID) {
	owner := std.GetOrigCaller()
	collection, found := getCollectionByOwner(owner)
	if !found {
		panic("book collection is empty")
	}

	if _, found = collection.Remove(id); !found {
		panic("book not found")
	}
}

func Render(path string) string {
	parts := strings.Split(path, "/")
	c := len(parts)

	switch {
	case c == 1:
		id, err := strconv.Atoi(parts[0])
		if err != nil {
			return "Invalid collection ID"
		}

		cID := libro.CollectionID(id)
		collection, found := getCollection(cID)
		if !found {
			return "Book collection is empty"
		}

		return collection.Render()
	default:
		return "Not Found"
	}
}
