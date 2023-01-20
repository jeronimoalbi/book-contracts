package book

import (
	"strconv"

	"gno.land/p/demo/ufmt"
)

type ID uint64

func (id ID) String() string {
	return strconv.Itoa(int(id))
}

func NewBook(id ID, title string) Book {
	return Book{
		id:    id,
		title: title,
	}
}

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

func (self Book) Render() string {
	return ufmt.Sprintf("[#%s] %s", self.id.String(), self.title)
}
