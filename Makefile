# Name of the key to use for the transactions
KEY_NAME ?= test

# Remote gno.land node address
REMOTE ?= localhost:26657

.PHONY: help
help:
	@echo "Available make commands:"
	@cat Makefile | grep '^[a-z][^:]*:' | cut -d: -f1 | sort | sed 's/^/  /'

all: install

install-package-book:
	@echo Adding book package...
	gnokey maketx addpkg \
			--pkgpath="gno.land/p/demo/jeronimoalbi/book" \
			--pkgdir="p/demo/jeronimoalbi/book" \
			--deposit="1ugnot" \
			--gas-fee="1ugnot" \
			--gas-wanted="2000000" \
			--broadcast="true" \
			--chainid="dev" \
			--remote="$(REMOTE)" \
			$(KEY_NAME)

install-realm-library:
	@echo Adding library realm...
	gnokey maketx addpkg \
			--pkgpath="gno.land/r/demo/jeronimoalbi/library" \
			--pkgdir="r/demo/jeronimoalbi/library" \
			--deposit="1ugnot" \
			--gas-fee="1ugnot" \
			--gas-wanted="2000000" \
			--broadcast="true" \
			--chainid="dev" \
			--remote="$(REMOTE)" \
			$(KEY_NAME)

# install-token:
# 	@echo Adding PAGE token...
# 	@gnokey maketx addpkg \
# 			--pkgpath="gno.land/r/book/page" \
# 			--pkgdir=r/book/page \
# 			--deposit="1ugnot" \
# 			--gas-fee="1ugnot" \
# 			--gas-wanted="2000000" \
# 			--broadcast="true" \
# 			--chainid="dev" \
# 			--remote="$(REMOTE)" \
# 			$(KEY_NAME)
#
# install-club:
# 	@echo Adding club realm...
# 	@gnokey maketx addpkg \
# 			--pkgpath="gno.land/r/book/club" \
# 			--pkgdir=r/book/club \
# 			--deposit="1ugnot" \
# 			--gas-fee="1ugnot" \
# 			--gas-wanted="2000000" \
# 			--broadcast="true" \
# 			--chainid="dev" \
# 			--remote="$(REMOTE)" \
# 			$(KEY_NAME)

install-packages: install-package-book

install-realms: install-realm-library

install: install-packages install-realms

populate-library:
	@echo Adding example book to the library
	@gnokey maketx call \
			--pkgpath="gno.land/r/demo/jeronimoalbi/library" \
			--func="Add" \
			--args="The Hitchhiker's Guide to the Galaxy" \
			--gas-fee="1ugnot" \
			--gas-wanted="2000000" \
			--broadcast="true" \
			--chainid="dev" \
			--remote="$(REMOTE)" \
			$(KEY_NAME)

populate: populate-library
