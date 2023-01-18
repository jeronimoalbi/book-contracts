package libro

import (
	"strconv"

	"gno.land/p/demo/ufmt"
)

type BookID uint64

func (id BookID) String() string {
	return strconv.Itoa(int(id))
}

func NewBook(id BookID, title, slug string) Book {
	return Book{
		id:    id,
		title: title,
		slug:  slug,
	}
}

type Book struct {
	id    BookID
	title string
	slug  string

	ISBN string
}

func (b Book) ID() BookID {
	return b.id
}

func (b Book) Title() string {
	return b.title
}

func (b *Book) SetTitle(title string) {
	b.title = title
}

func (b Book) Slug() string {
	// TODO: Generate slug from title
	return b.slug
}

func (b Book) Render() string {
	return ufmt.Sprintf("[#%s] %s", b.id.String(), b.title)
}
