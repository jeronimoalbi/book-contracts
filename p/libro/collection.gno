package libro

import (
	"strconv"
	"strings"

	"gno.land/p/demo/avl"
)

type CollectionID uint64

func (id CollectionID) String() string {
	return strconv.Itoa(int(id))
}

func NewCollection(id CollectionID) *Collection {
	return &Collection{id: id}
}

type Collection struct {
	id    CollectionID
	books avl.Tree
}

func (self Collection) ID() CollectionID {
	return self.id
}

func (self Collection) Add(b Book) {
	bID := b.ID()
	self.books.Set(bID.String(), &b)
}

func (self Collection) Remove(id BookID) (b Book, found bool) {
	return self.books.Remove(id.String())
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
