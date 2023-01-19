package libro

import (
	"strconv"

	"gno.land/p/demo/ufmt"
)

type BookID uint64

func (id BookID) String() string {
	return strconv.Itoa(int(id))
}

func NewBook(id BookID, title string) Book {
	return Book{
		id:    id,
		title: title,
	}
}

type Book struct {
	id    BookID
	title string
}

func (self Book) ID() BookID {
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
