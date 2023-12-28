package book

import (
	"strconv"

	"gno.land/p/demo/ufmt"
)

// ID defines an ID type.
type ID uint64

func (id ID) String() string {
	return strconv.Itoa(int(id))
}

// New creates a new book.
func New(id ID, title string) *Book {
	return &Book{
		id:    id,
		title: title,
	}
}

// Book defines a book.
type Book struct {
	id    ID
	title string
}

func (self Book) ID() ID {
	return self.id
}

func (self Book) Title() string {
	return self.title
}

func (self *Book) SetTitle(title string) {
	self.title = title
}

// Render returns a string that represents the book.
func (self Book) Render() string {
	return ufmt.Sprintf("[#%s] %s", self.id.String(), self.title)
}
