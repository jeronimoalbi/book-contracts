// Contract tests
//
// All tests change the virtual machine state and are not atomic
// so when a test changes the state it affect the tests that are
// executed after.
package library

import (
	"fmt"
	"std"
	"strings"
	"testing"

	"gno.land/p/demo/jeronimoalbi/book"
	"gno.land/p/demo/testutils"

	contract "gno.land/r/demo/jeronimoalbi/library"
)

func TestAdd(t *testing.T) {
	// Arrange
	title := "Foo"
	secondTitle := "Bar"
	wantOutput := fmt.Sprintf("[#1] %s\\n[#2] %s\\n", title, secondTitle)

	owner := testutils.TestAddress("add/owner")
	std.TestSetOrigCaller(owner)

	// Act
	bookID := contract.Add(title)
	secondBookID := contract.Add(secondTitle)

	// Assert
	if bookID != 1 {
		t.Errorf("expected book ID 1, got: %d", bookID)
	}

	if secondBookID != 2 {
		t.Errorf("expected second book ID 2, got: %d", secondBookID)
	}

	if v := render(t, owner.String()); v != wantOutput {
		t.Errorf("expected render output '%s', got: '%s'", wantOutput, v)
	}
}

func TestBurn(t *testing.T) {
	owner := testutils.TestAddress("burn/owner")
	std.TestSetOrigCaller(owner)

	cases := []struct {
		name  string
		err   string
		setup func() book.ID
	}{
		{
			name: "empty collection",
			err:  "book collection is empty",
			setup: func() book.ID {
				return 99
			},
		},
		{
			name: "book not found",
			err:  "book not found",
			setup: func() book.ID {
				// Add a single book to make sure the account has
				// a collection and return an invalid book ID
				id := contract.Add("Foo")
				return book.ID(id + 1)
			},
		},
		{
			name: "ok",
			setup: func() book.ID {
				return book.ID(contract.Add("Foo"))
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			bookID := tc.setup()

			// Act
			reason := handlePanic(t, func() {
				contract.Burn(bookID)
			})

			// Assert
			if tc.err != "" {
				assertPanicReason(t, tc.err, reason)
			} else {
				if _, found := contract.GetBook(owner, bookID); found {
					t.Error("expected book to be burned")
				}
			}
		})
	}
}

func TestLend(t *testing.T) {
	owner := testutils.TestAddress("lend/owner")
	borrower := testutils.TestAddress("lend/borrower")

	cases := []struct {
		name  string
		err   string
		setup func(*testing.T) book.ID
	}{
		{
			name: "empty collection",
			err:  "lender has no books",
			setup: func(*testing.T) book.ID {
				std.TestSetOrigCaller(owner)
				return 42
			},
		},
		{
			name: "lend book of different owner",
			err:  "lender doesn't own the book",
			setup: func(t *testing.T) book.ID {
				owner2 := testutils.TestAddress("lend/owner2")
				_ = createBook(t, owner, "Cosmos: A Personal Voyage")
				id := createBook(t, owner2, "Don quijote")
				std.TestSetOrigCaller(owner)
				return id
			},
		},
		{
			name: "ok",
			setup: func(t *testing.T) book.ID {
				return createBook(t, owner, "Cosmos: A Personal Voyage")
			},
		},
		{
			name: "book is lent",
			err:  "book is lent",
			setup: func(t *testing.T) book.ID {
				id := createBook(t, owner, "Cosmos: A Personal Voyage")
				lendBook(t, owner, borrower, id)
				return id
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			bookID := tc.setup(t)

			// Act
			reason := handlePanic(t, func() {
				contract.Lend(borrower, bookID)
			})

			// Assert
			if tc.err != "" {
				assertPanicReason(t, tc.err, reason)
			} else {
				if v := contract.GetBorrower(bookID); v != borrower.String() {
					t.Errorf("expected borrower '%s', got: '%s'", borrower, v)
				}

				if !contract.IsLent(bookID) {
					t.Error("expected book to be lent")
				}
			}
		})
	}
}

func TestTransfer(t *testing.T) {
	owner := testutils.TestAddress("transfer/owner")
	newOwner := testutils.TestAddress("transfer/newOwner")
	bookID := createBook(t, owner, "Cosmos: A Personal Voyage")

	cases := []struct {
		name     string
		newOwner std.Address
		err      string
		setup    func(*testing.T) book.ID
	}{
		{
			name:     "transfer to current owner",
			err:      "transfer to the current owner is not allowed",
			newOwner: owner,
			setup: func(*testing.T) book.ID {
				std.TestSetOrigCaller(owner)
				return bookID
			},
		},
		{
			name:     "transfer from empty collection",
			err:      "book collection is empty",
			newOwner: owner,
			setup: func(*testing.T) book.ID {
				// Change the caller to an owner without book collection
				std.TestSetOrigCaller(newOwner)
				return bookID
			},
		},
		{
			name:     "book not found",
			err:      "book not found",
			newOwner: newOwner,
			setup: func(*testing.T) book.ID {
				std.TestSetOrigCaller(owner)
				return 99
			},
		},
		{
			name:     "ok",
			newOwner: newOwner,
			setup: func(*testing.T) book.ID {
				std.TestSetOrigCaller(owner)
				return bookID
			},
		},
		{
			name:     "book already lent",
			err:      "book is lent",
			newOwner: newOwner,
			setup: func(t *testing.T) book.ID {
				// Create and lend a book
				id := createBook(t, owner, "The Hitchhiker's Guide to the Galaxy")
				lendBook(t, owner, newOwner, id)
				std.TestSetOrigCaller(owner)
				return id
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			bookID := tc.setup(t)

			// Act
			reason := handlePanic(t, func() {
				contract.Transfer(tc.newOwner, bookID)
			})

			// Assert
			if tc.err != "" {
				assertPanicReason(t, tc.err, reason)
			} else {
				if _, found := contract.GetBook(owner, bookID); found {
					t.Error("expected book not found")
				}

				if _, found := contract.GetBook(newOwner, bookID); !found {
					t.Error("expected book to belong to the new owner")
				}
			}
		})
	}
}

func TestReturn(t *testing.T) {
	owner := testutils.TestAddress("return/owner")
	borrower := testutils.TestAddress("return/borrower")

	cases := []struct {
		name  string
		err   string
		setup func(*testing.T) book.ID
	}{
		{
			name: "ok",
			setup: func(t *testing.T) book.ID {
				id := createBook(t, owner, "Cosmos: A Personal Voyage")
				lendBook(t, owner, borrower, id)
				std.TestSetOrigCaller(borrower)
				return id
			},
		},
		{
			name: "book not lent",
			err:  "book is not lent",
			setup: func(t *testing.T) book.ID {
				id := createBook(t, owner, "Cosmos: A Personal Voyage")
				std.TestSetOrigCaller(borrower)
				return id
			},
		},
		{
			name: "return by another account",
			err:  "book can only be returned by the borrower",
			setup: func(t *testing.T) book.ID {
				id := createBook(t, owner, "Cosmos: A Personal Voyage")
				borrower2 := testutils.TestAddress("return/borrower2")
				lendBook(t, owner, borrower2, id)
				std.TestSetOrigCaller(borrower)
				return id
			},
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			// Arrange
			bookID := tc.setup(t)

			// Act
			reason := handlePanic(t, func() {
				contract.Return(bookID)
			})

			// Assert
			if tc.err != "" {
				assertPanicReason(t, tc.err, reason)
			} else {
				if contract.IsLent(bookID) {
					t.Error("expected book not to be lent")
				}
			}
		})
	}
}

func render(t *testing.T, path string) string {
	t.Helper()
	return strings.ReplaceAll(Render(path), "\n", "\\n")
}

func handlePanic(t *testing.T, fn func()) (reason string) {
	t.Helper()

	defer func() {
		if r := recover(); r != nil {
			if err, _ := r.(error); err != nil {
				reason = err.Error()
			} else {
				reason = fmt.Sprint(r)
			}
		}
	}()

	fn()
	return
}

func lendBook(t *testing.T, owner, borrower std.Address, id book.ID) {
	t.Helper()

	std.TestSetOrigCaller(owner)
	reason := handlePanic(t, func() {
		contract.Lend(borrower, id)
	})
	if reason != "" {
		t.Fatal(reason)
	}
}

func createBook(t *testing.T, owner std.Address, title string) book.ID {
	std.TestSetOrigCaller(owner)
	return book.ID(contract.Add(title))
}

func assertPanicReason(t *testing.T, expected, actual string) {
	if expected != actual {
		t.Errorf("expected panic with '%s', got: '%s'", expected, actual)
	}
}
