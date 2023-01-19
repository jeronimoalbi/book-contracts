# Libro Contracts

## Install

Add `libro` package to the whitelisted `gno.land/p/demo` namespace:

```sh
gnokey maketx addpkg KEY_NAME \
    --pkgpath "gno.land/p/demo/libro" \
    --pkgdir p/libro \
    --deposit 100000000ugnot \
    --gas-fee 1000000ugnot \
    --gas-wanted 2000000 \
    --broadcast true \
    --chainid dev \
    --remote localhost:26657
```

Add realm for book collections:

```sh
gnokey maketx addpkg KEY_NAME \
    --pkgpath "gno.land/r/libro/collection" \
    --pkgdir r/libro/collection \
    --deposit 100000000ugnot \
    --gas-fee 1000000ugnot \
    --gas-wanted 2000000 \
    --broadcast true \
    --chainid dev \
    --remote localhost:26657
```

Add a book to start the collection:

```sh
gnokey maketx call KEY_NAME \
    --pkgpath "gno.land/r/libro/collection" \
    --func "AddBook" \
    --args "The Hitchhiker's Guide to the Galaxy" \
    --gas-fee 1000000ugnot \
    --gas-wanted 2000000 \
    --broadcast true \
    --chainid dev \
    --remote localhost:26657
```

Add realm for the `PAGE` token:

```sh
gnokey maketx addpkg KEY_NAME \
    --pkgpath "gno.land/r/libro/page" \
    --pkgdir r/libro/page \
    --deposit 100000000ugnot \
    --gas-fee 1000000ugnot \
    --gas-wanted 2000000 \
    --broadcast true \
    --chainid dev \
    --remote localhost:26657
```
