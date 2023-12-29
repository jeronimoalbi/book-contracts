package book

import (
	"fmt"
	"testing"
)

func TestID(t *testing.T) {
	// Arrange
	raw := uint64(42)

	// Act
	id := ID(raw)

	// Assert
	if v := id.String(); v != "42" {
		t.Errorf("expected string 42, got: %s", v)
	}

	if id != raw {
		t.Error("expected ID to match uint64 ID")
	}
}

func TestBook(t *testing.T) {
	// Arrange
	id := ID(42)
	title := "Cosmos: A Personal Voyage"
	markdown := fmt.Sprintf("[#%d] %s", id, title)

	// Act
	book := New(id, title)

	// Assert
	if v := book.ID(); v != id {
		t.Errorf("expected ID %d, got: %d", id, v)
	}

	if v := book.Title(); v != title {
		t.Errorf("expected title '%s', got: '%s'", title, v)
	}

	if v := book.Render(); v != markdown {
		t.Errorf("expected render output '%s', got: '%s'", markdown, v)
	}
}

func TestBookSetters(t *testing.T) {
	// Arrange
	book := New(0, "")
	title := "Cosmos: A Personal Voyage"

	// Act
	book.SetTitle(title)

	// Assert
	if v := book.Title(); v != title {
		t.Errorf("expected title '%s', got: '%s'", title, v)
	}
}
