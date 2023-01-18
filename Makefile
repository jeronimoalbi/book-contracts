# Name of the key to use for the transactions
KEY_NAME = test1

# Password to access the key
PASSWORD = 123

all: install

install-package:
	@echo Adding package...
	@gnokey maketx addpkg $(KEY_NAME) \
			--pkgpath "gno.land/p/demo/libro" \
			--pkgdir p/libro \
			--deposit 100000000ugnot \
			--gas-fee 1000000ugnot \
			--gas-wanted 2000000 \
			--broadcast true \
			--chainid dev \
			--remote localhost:26657 \
			--insecure-password-stdin <<< "$(PASSWORD)"

install-collection:
	@echo Adding collection realm...
	@gnokey maketx addpkg $(KEY_NAME) \
			--pkgpath "gno.land/r/libro/collection" \
			--pkgdir r/libro/collection \
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
			--pkgpath "gno.land/r/libro/page" \
			--pkgdir r/libro/page \
			--deposit 100000000ugnot \
			--gas-fee 1000000ugnot \
			--gas-wanted 2000000 \
			--broadcast true \
			--chainid dev \
			--remote localhost:26657 \
			--insecure-password-stdin <<< "$(PASSWORD)"

install: install-package install-collection install-token

populate:
	@echo Adding example book to the collection
	@gnokey maketx call $(KEY_NAME) \
			--pkgpath "gno.land/r/libro/collection" \
			--func "AddBook" \
			--args "The Hitchhiker's Guide to the Galaxy" \
			--args "the-hitchhikers-guide-to-the-galaxy" \
			--gas-fee 1000000ugnot \
			--gas-wanted 2000000 \
			--broadcast true \
			--chainid dev \
			--remote localhost:26657 \
			--insecure-password-stdin <<< "$(PASSWORD)"
