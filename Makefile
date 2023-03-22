# Name of the key to use for the transactions
KEY_NAME = test1

# Password to access the key
PASSWORD = 123

all: install

install-collection:
	@echo Adding collection realm...
	@gnokey maketx addpkg $(KEY_NAME) \
			--pkgpath "gno.land/r/book/collection" \
			--pkgdir r/book/collection \
			--deposit 100000000ugnot \
			--gas-fee 1000000ugnot \
			--gas-wanted 2000000 \
			--broadcast true \
			--chainid dev \
			--remote localhost:26657 \
			--insecure-password-stdin <<< "$(PASSWORD)"

install-token:
	@echo Adding PAGE token...
	@gnokey maketx addpkg $(KEY_NAME) \
			--pkgpath "gno.land/r/book/page" \
			--pkgdir r/book/page \
			--deposit 100000000ugnot \
			--gas-fee 1000000ugnot \
			--gas-wanted 2000000 \
			--broadcast true \
			--chainid dev \
			--remote localhost:26657 \
			--insecure-password-stdin <<< "$(PASSWORD)"

install-club:
	@echo Adding club realm...
	@gnokey maketx addpkg $(KEY_NAME) \
			--pkgpath "gno.land/r/book/club" \
			--pkgdir r/book/club \
			--deposit 100000000ugnot \
			--gas-fee 1000000ugnot \
			--gas-wanted 2000000 \
			--broadcast true \
			--chainid dev \
			--remote localhost:26657 \
			--insecure-password-stdin <<< "$(PASSWORD)"

install: install-collection install-token install-club

populate:
	@echo Adding example book to the collection
	@gnokey maketx call $(KEY_NAME) \
			--pkgpath "gno.land/r/book/collection" \
			--func "Add" \
			--args "The Hitchhiker's Guide to the Galaxy" \
			--gas-fee 1000000ugnot \
			--gas-wanted 2000000 \
			--broadcast true \
			--chainid dev \
			--remote localhost:26657 \
			--insecure-password-stdin <<< "$(PASSWORD)"
