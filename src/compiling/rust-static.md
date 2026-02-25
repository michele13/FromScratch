# Compile static rust programs

we first create a simple hello.rs file:

```bash
cat > hello.rs << "EOF"

fn main(){
	println!("Hello World");
}

EOF	
```

## On Debian

On debian we install the follwing packages:

```bash
	apt update
	apt install -y build-essential rustup libssl-dev zlib1g-dev
	rustup default stable
	rustup target add x86_64-unknown-linux-musl
```

Now we can compile with:

```bash
	rustc --target x86_64-unknown-linux-musl hello.rs
```

if we run

```bash
	ldd hello
```

it says

	statically linked


## On Alpine

Install the following packages:

```bash
	apk add alpine-sdk openssl-dev openssl-libs-static zlib-dev zlib-static rust cargo
```