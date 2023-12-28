package book

import (
	"strings"

	"gno.land/p/demo/avl"
)

// NewCollection creates a new book collection.
func NewCollection() Collection {
	return Collection{
		books: avl.NewTree(),
	}
}

// Collection contains a list of books.
type Collection struct {
	books *avl.Tree // Book ID -> *Book
}

// Has checks if a book is part of the collection.
func (self Collection) Has(bookID ID) bool {
	return self.books.Has(bookID.String())
}

// Add adds a book to the collection.
func (self Collection) Add(b *Book) {
	self.books.Set(b.ID().String(), b)
}

// Remove removes a book from the collection.
func (self Collection) Remove(bookID ID) (*Book, bool) {
	if v, found := self.books.Remove(bookID.String()); found {
		return v.(*Book), true
	}
	return nil, false
}

// Get returns a book from the collection.
func (self Collection) Get(bookID ID) (*Book, bool) {
	if v, found := self.books.Get(bookID.String()); found {
		return v.(*Book), true
	}
	return nil, false
}

// Render returns a string that lists the collection of books.
func (self Collection) Render() string {
	var output strings.Builder

	self.books.Iterate("", "", func(_ string, value interface{}) bool {
		book := value.(*Book)
		output.WriteString(book.Render())
		output.WriteRune('\n')
		return false
	})

	return output.String()
}
