# Compiling mdbook from source

In this article we will build `mdbook` and the community addon `mdbook-typst`  from source using the latest git sources.

Make sure you setup [rust for static compiling](rust-static.md) first.

## Compile mdbook

Download the sources:

```bash
    git clone --depth 1 https://github.com/rust-lang/mdBook.git
```    
Now we run the build:

```bash
    cargo build --release --locked --target x86_64-unknown-linux-musl
```

you can now find the `mdbook` static executable in `target/x86_64-unknown-linux-musl/release`

## Compilie typst

Download the sources:

```bash
    git clone --depth 1 https://github.com/typst/typst/
```
Compile the package:

```bash
    cargo build --features vendor-openssl --release --locked --target x86_64-unknown-linux-musl
```

you can now find the `typst` static executable in `target/x86_64-unknown-linux-musl/release`

## Compilie mdbook-typst

Download the sources:

```bash
    git clone --depth 1 https://github.com/LegNeato/mdbook-typst
```
Compile the package:

```bash
    cargo build --release --locked --target x86_64-unknown-linux-musl
```

you can now find the `mdbook-typst` static executable in `target/x86_64-unknown-linux-musl/release`