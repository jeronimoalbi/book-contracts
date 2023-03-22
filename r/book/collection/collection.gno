package collection

import (
	"strings"

	"gno.land/p/demo/avl"
)

// Collection contains a list of books.
type Collection struct {
	books avl.Tree // BookID -> *Book
}

func (self Collection) Has(id BookID) bool {
	return self.books.Has(id.String())
}

func (self Collection) Add(b *Book) {
	self.books.Set(b.ID().String(), b)
}

func (self Collection) Remove(id BookID) (*Book, bool) {
	if v, found := self.books.Remove(id.String()); found {
		return v.(*Book), true
	}
	return nil, false
}

func (self Collection) Get(id BookID) (*Book, bool) {
	if v, found := self.books.Get(id.String()); found {
		return v.(*Book), true
	}
	return nil, false
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
