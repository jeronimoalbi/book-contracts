# Name of the key to use for the transactions
KEY_NAME = test1

# Remote gno.land node address
REMOTE = localhost:26657

all: install

install-collection:
	@echo Adding collection realm...
	gnokey maketx addpkg \
			--pkgpath="gno.land/r/book/collection" \
			--pkgdir="r/book/collection" \
			--deposit="1ugnot" \
			--gas-fee="1ugnot" \
			--gas-wanted="2000000" \
			--broadcast="true" \
			--chainid="dev" \
			--remote="$(REMOTE)" \
			$(KEY_NAME)

install-token:
	@echo Adding PAGE token...
	@gnokey maketx addpkg \
			--pkgpath="gno.land/r/book/page" \
			--pkgdir=r/book/page \
			--deposit="1ugnot" \
			--gas-fee="1ugnot" \
			--gas-wanted="2000000" \
			--broadcast="true" \
			--chainid="dev" \
			--remote="$(REMOTE)" \
			$(KEY_NAME)

install-club:
	@echo Adding club realm...
	@gnokey maketx addpkg \
			--pkgpath="gno.land/r/book/club" \
			--pkgdir=r/book/club \
			--deposit="1ugnot" \
			--gas-fee="1ugnot" \
			--gas-wanted="2000000" \
			--broadcast="true" \
			--chainid="dev" \
			--remote="$(REMOTE)" \
			$(KEY_NAME)

install: install-collection install-token install-club

populate:
	@echo Adding example book to the collection
	@gnokey maketx call \
			--pkgpath="gno.land/r/book/collection" \
			--func="Add" \
			--args="The Hitchhiker's Guide to the Galaxy" \
			--gas-fee="1ugnot" \
			--gas-wanted="2000000" \
			--broadcast="true" \
			--chainid="dev" \
			--remote="$(REMOTE)" \
			$(KEY_NAME)
