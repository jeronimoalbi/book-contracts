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

func (c Collection) ID() CollectionID {
	return c.id
}

func (c Collection) Add(b Book) {
	bID := b.ID()
	c.books.Set(bID.String(), &b)
}

func (c Collection) Remove(id BookID) (b Book, found bool) {
	return c.books.Remove(id.String())
}

func (c Collection) Render() string {
	var builder strings.Builder

	c.books.Iterate("", "", func(n *avl.Node) bool {
		b := n.Value().(*Book)
		builder.WriteString(b.Render())
		builder.WriteRune('\n')

		return false
	})

	return builder.String()
}
