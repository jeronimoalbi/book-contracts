package collection

import (
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
)

// ID defines the book collection ID type.
type ID uint64

func (id ID) String() string {
	return strconv.Itoa(int(id))
}

func New(id ID) *Collection {
	return &Collection{id: id}
}

// Collection contains a list of books.
type Collection struct {
	id    ID
	books avl.Tree // BookID -> *Book
}

func (self Collection) ID() ID {
	return self.id
}

func (self Collection) Has(id BookID) bool {
	return self.books.Has(id.String())
}

func (self Collection) Add(b *Book) {
	bID := b.ID()
	self.books.Set(bID.String(), b)
}

func (self Collection) Remove(id BookID) (*Book, bool) {
	v, found := self.books.Remove(id.String())
	return v.(*Book), found
}

func (self Collection) Get(id BookID) (*Book, bool) {
	v, found := self.books.Get(id.String())
	return v.(*Book), found
}

func (self Collection) Render() string {
	var builder strings.Builder

	self.books.Iterate("", "", func(n *avl.Node) bool {
		b := n.Value().(*Book)
		builder.WriteString(b.Render())
		builder.WriteRune('\n')
		return false
	})

	return builder.String()
}
