package book

import (
	"fmt"
	"strings"
	"testing"
)

func TestNewCollection(t *testing.T) {
	// Act
	c := NewCollection()
	fakeID := ID(1)

	// Assert
	if c.Has(fakeID) {
		t.Error("expected false when checking if a book exists")
	}

	if _, ok := c.Remove(fakeID); ok {
		t.Error("expected remove book to fail")
	}

	if _, ok := c.Get(fakeID); ok {
		t.Error("expected get book to fail")
	}

	if v := c.Render(); v != "" {
		t.Error("expected render output to be empty")
	}
}

func TestCollectionAdd(t *testing.T) {
	// Arrange
	c := NewCollection()

	// Act
	c.Add(New(1, "Foo"))
	c.Add(New(2, "Bar"))

	// Assert
	if v := c.Size(); v != 2 {
		t.Errorf("expected size to be 2, got %d", v)
	}
}

func TestCollectionHas(t *testing.T) {
	// Arrange
	book := New(1, "Foo")
	c := NewCollection()
	c.Add(book)
	c.Add(New(2, "Bar"))

	// Act
	exists := c.Has(book.ID())

	// Assert
	if !exists {
		t.Error("expected book to exist")
	}
}

func TestCollectionRemove(t *testing.T) {
	// Arrange
	book := New(1, "Foo")
	c := NewCollection()
	c.Add(book)
	c.Add(New(2, "Bar"))

	// Act
	b, exists := c.Remove(book.ID())

	// Assert
	if !exists {
		t.Error("expected book to exist")
	}

	if v := c.Size(); v != 1 {
		t.Errorf("expected collection size to be 1, got: %d", v)
	}

	if b != book {
		t.Error("expected removed book to be returned")
	}
}

func TestCollectionGet(t *testing.T) {
	// Arrange
	book := New(1, "Foo")
	c := NewCollection()
	c.Add(book)
	c.Add(New(2, "Bar"))

	// Act
	b, exists := c.Get(book.ID())

	// Assert
	if !exists {
		t.Error("expected book to exist")
	}

	if b != book {
		t.Error("expected book to be returned")
	}
}

func TestCollectionRender(t *testing.T) {
	// Arrange
	c := NewCollection()
	c.Add(New(1, "Foo"))
	c.Add(New(2, "Bar"))
	wantOutput := fmt.Sprintf("[#1] Foo\\n[#2] Bar\\n")

	// Act
	output := c.Render()

	// Assert
	if v := strings.ReplaceAll(output, "\n", "\\n"); v != wantOutput {
		t.Errorf("expected render output '%s', got '%s'", wantOutput, v)
	}
}
