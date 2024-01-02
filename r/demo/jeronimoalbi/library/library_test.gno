package library

import (
	"std"
	"testing"

	"gno.land/p/demo/jeronimoalbi/book"
)

func TestLibraryAddCollection(t *testing.T) {
	address := std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")
	cases := []struct {
		name string
		addr std.Address
		err  string
	}{
		{
			name: "ok",
			addr: "g13m34fka0rqw7p03axtg26l8k29sunvzua6zk58",
		},
		{
			name: "error",
			addr: address,
			err:  "owner already have a book collection",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			library := New()
			library.AddCollection(address, book.NewCollection())

			// Act
			err := library.AddCollection(tc.addr, book.NewCollection())

			// Assert
			if tc.err != "" {
				if err == nil {
					t.Errorf("expected error '%s' to be returned", tc.err)
				} else if v := err.Error(); v != tc.err {
					t.Errorf("expected error '%s', got: '%v'", tc.err, err)
				}

				if v := library.Size(); v != 1 {
					t.Errorf("expected size to be 1, got: %d", v)
				}
			} else {
				if err != nil {
					t.Errorf("expected no error, got: %v", err)
				}

				if !library.HasCollection(tc.addr) {
					t.Error("expected collection to exist")
				}

				if v := library.Size(); v != 2 {
					t.Errorf("expected size to be 2, got: %d", v)
				}
			}
		})
	}
}

func TestLibraryHasCollection(t *testing.T) {
	// Arrange
	address := std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")
	library := New()
	library.AddCollection(address, book.NewCollection())
	library.AddCollection("g13m34fka0rqw7p03axtg26l8k29sunvzua6zk58", book.NewCollection())

	// Act
	exists := library.HasCollection(address)

	// Assert
	if !exists {
		t.Error("expected collection to exist")
	}
}

func TestLibraryGetCollection(t *testing.T) {
	// Arrange
	collection := book.NewCollection()
	address := std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")
	library := New()
	library.AddCollection(address, collection)
	library.AddCollection("g13m34fka0rqw7p03axtg26l8k29sunvzua6zk58", book.NewCollection())

	// Act
	c, exists := library.GetCollection(address)

	// Assert
	if !exists {
		t.Error("expected collection to exist")
	}

	if c != collection {
		t.Error("expected collection to be returned")
	}
}

func TestLibraryLend(t *testing.T) {
	owner := std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")
	borrower := std.Address("g13m34fka0rqw7p03axtg26l8k29sunvzua6zk58")

	cases := []struct {
		name  string
		setup func(Library) book.ID
		err   string
	}{
		{
			name: "ok",
			setup: func(l Library) book.ID {
				// Add a collection with a book but for current owner
				b := book.New(42, "Foo")
				c := book.NewCollection()
				c.Add(b)
				l.AddCollection(owner, c)
				return b.ID()
			},
		},
		{
			name: "empty collection",
			err:  "lender has no books",
			setup: func(l Library) book.ID {
				// Don't add a collection for the current owner
				return 42
			},
		},
		{
			name: "third party owned book",
			err:  "lender doesn't own the book",
			setup: func(l Library) book.ID {
				// Add a collection for the current owner and another
				// collection with a single book but to another owner.
				b := book.New(42, "Foo")
				c := book.NewCollection()
				c.Add(b)
				l.AddCollection(owner, book.NewCollection())
				l.AddCollection("g1us8428u2a5satrlxzagqqa5m6vmuze025anjlj", c)
				return b.ID()
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			library := New()
			bookID := tc.setup(library)

			// Act
			err := library.Lend(owner, borrower, bookID)

			// Assert
			if tc.err != "" {
				if err == nil {
					t.Errorf("expected error '%s' to be returned", tc.err)
				} else if v := err.Error(); v != tc.err {
					t.Errorf("expected error '%s', got: '%s'", tc.err, v)
				}

				if library.IsLent(bookID) {
					t.Error("expected book to be available")
				}

				if v, _ := library.GetBorrower(bookID); v != "" {
					t.Errorf("expected borrower to be empty, got: '%s'", v)
				}
			} else {
				if err != nil {
					t.Errorf("expected no error, got: %s", err.Error())
				}

				if !library.IsLent(bookID) {
					t.Error("expected book to be lent")
				}

				if v, _ := library.GetBorrower(bookID); v != borrower {
					t.Errorf("expected borrower to be '%s', got: '%s'", borrower, v)
				}
			}
		})
	}
}

func TestLibraryReturn(t *testing.T) {
	owner := std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")
	borrower := std.Address("g13m34fka0rqw7p03axtg26l8k29sunvzua6zk58")

	std.TestSetOrigCaller(borrower)

	cases := []struct {
		name  string
		setup func(Library) book.ID
		err   string
	}{
		{
			name: "ok",
			setup: func(l Library) book.ID {
				b := book.New(42, "Foo")
				c := book.NewCollection()
				c.Add(b)
				l.AddCollection(owner, c)
				l.Lend(owner, borrower, b.ID())
				return b.ID()
			},
		},
		{
			name: "book not lent",
			err:  "book is not lent",
			setup: func(l Library) book.ID {
				b := book.New(42, "Foo")
				c := book.NewCollection()
				c.Add(b)
				l.AddCollection(owner, c)
				return b.ID()
			},
		},
		{
			name: "book lent to another account",
			err:  "book can only be returned by the borrower",
			setup: func(l Library) book.ID {
				b := book.New(42, "Foo")
				c := book.NewCollection()
				c.Add(b)
				l.AddCollection(owner, c)
				l.Lend(owner, "g1us8428u2a5satrlxzagqqa5m6vmuze025anjlj", b.ID())
				return b.ID()
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			library := New()
			bookID := tc.setup(library)

			// Act
			err := library.Return(bookID)

			// Assert
			if tc.err != "" {
				if err == nil {
					t.Errorf("expected error '%s' to be returned", tc.err)
				} else if v := err.Error(); v != tc.err {
					t.Errorf("expected error '%s', got: '%v'", tc.err, v)
				}
			} else {
				if err != nil {
					t.Errorf("expected no error, got: %s", err.Error())
				}

				if library.IsLent(bookID) {
					t.Error("expected book to be returned")
				}
			}
		})
	}
}

func TestLibraryGetBook(t *testing.T) {
	// Arrange
	testBook := book.New(42, "Foo")
	collection := book.NewCollection()
	collection.Add(testBook)

	owner := std.Address("g1jg8mtutu9khhfwc4nxmuhcpftf0pajdhfvsqf5")
	library := New()
	library.AddCollection(owner, collection)

	cases := []struct {
		name   string
		bookID book.ID
		book   *book.Book
	}{
		{
			name:   "ok",
			bookID: 42,
			book:   testBook,
		},
		{
			name:   "not found",
			bookID: 999,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Act
			b, found := library.GetBook(owner, tc.bookID)

			// Assert
			if tc.book == nil {
				if b != nil {
					t.Errorf("expected no book to be found, got: %d", b.ID())
				}

				if found {
					t.Error("expected found to be false")
				}
			} else {
				if b != testBook {
					t.Errorf("expected book %d to be returned, got: %d", testBook.ID(), b.ID())
				}

				if !found {
					t.Error("expected found to be true")
				}
			}
		})
	}
}
