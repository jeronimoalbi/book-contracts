# Name of the key to use for the transactions
KEY_NAME ?= test

# Password of the key to use for the transactions
KEY_PASSWORD ?=

# Remote gno.land node address
REMOTE ?= localhost:26657

help:
	@echo "Available make commands:"
	@cat Makefile | grep '^[a-z][^:]*:' | cut -d: -f1 | sort | sed 's/^/  /'

all: install populate

install-package-book:
	@echo Adding book package...
	@gnokey maketx addpkg \
			-pkgpath="gno.land/p/demo/jeronimoalbi/book" \
			-pkgdir="p/demo/jeronimoalbi/book" \
			-deposit="1ugnot" \
			-gas-fee="1ugnot" \
			-gas-wanted="2000000" \
			-chainid="dev" \
			-remote="$(REMOTE)" \
			-broadcast \
			-insecure-password-stdin \
			$(KEY_NAME) <<< "$(KEY_PASSWORD)"

install-realm-library:
	@echo Adding library realm...
	@gnokey maketx addpkg \
			-pkgpath="gno.land/r/demo/jeronimoalbi/library" \
			-pkgdir="r/demo/jeronimoalbi/library" \
			-deposit="1ugnot" \
			-gas-fee="1ugnot" \
			-gas-wanted="2000000" \
			-chainid="dev" \
			-remote="$(REMOTE)" \
			-broadcast \
			-insecure-password-stdin \
			$(KEY_NAME) <<< "$(KEY_PASSWORD)"

install-realm-page:
	@echo Adding realm for PAGE token...
	@gnokey maketx addpkg \
			-pkgpath="gno.land/r/demo/jeronimoalbi/page" \
			-pkgdir=r/demo/jeronimoalbi/page \
			-deposit="1ugnot" \
			-gas-fee="1ugnot" \
			-gas-wanted="2000000" \
			-chainid="dev" \
			-remote="$(REMOTE)" \
			-broadcast \
			-insecure-password-stdin \
			$(KEY_NAME) <<< "$(KEY_PASSWORD)"

install-realm-bookclub:
	@echo Adding book club realm...
	@gnokey maketx addpkg \
			-pkgpath="gno.land/r/demo/jeronimoalbi/bookclub" \
			-pkgdir=r/demo/jeronimoalbi/bookclub \
			-deposit="1ugnot" \
			-gas-fee="1ugnot" \
			-gas-wanted="2000000" \
			-chainid="dev" \
			-remote="$(REMOTE)" \
			-broadcast \
			-insecure-password-stdin \
			$(KEY_NAME) <<< "$(KEY_PASSWORD)"

install-packages: install-package-book

install-realms: install-realm-library install-realm-page install-realm-bookclub

install: install-packages install-realms

populate-library:
	@echo Adding example book to the library
	@gnokey maketx call \
			-pkgpath="gno.land/r/demo/jeronimoalbi/library" \
			-func="Add" \
			-args="The Hitchhiker's Guide to the Galaxy" \
			-gas-fee="1ugnot" \
			-gas-wanted="2000000" \
			-chainid="dev" \
			-remote="$(REMOTE)" \
			-broadcast \
			-insecure-password-stdin \
			$(KEY_NAME) <<< "$(KEY_PASSWORD)"

populate: populate-library
