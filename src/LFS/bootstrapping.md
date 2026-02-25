# Bootstrapping LFS From Almost Nothing

We will build LFS starting from a static busybox binary and a static musl cross-compiler.

## 1. Preparations

create a directory where to build LFS. We will be using a unsare container.

```shell

mkdir -pv unshare-host/{bin,proc,sys,dev,root,lib}
install -d -m 1777 unshare-root/tmp
cp /bin/busybox unshare-host/bin/busybox
for x in $(./unshare-host/bin/busybox --list); do
  ln -s busybox ./unshare-host/bin/$x
done

```

### Setting up the Environment

create a `.profile` file inside the root *HOME* directory of the container

```shell

cat > unshare-host/root/.profile << "EOF"

PATH=/static/bin:/cross-tools/bin:$PATH
export PATH
EOF

```

create a script that will be used to enter inside the container:

```shell

cd unshare-host

cat > init << "EOF"
#!/bin/sh
ROOT=$1
[ -n "$ROOT" ] || ROOT="$PWD"
$ROOT/bin/busybox unshare -m -u -i -n -p -U -f -r --mount-proc chroot $ROOT /bin/busybox ash shell.sh
EOF

cat > shell.sh << "EOF"
#!/bin/busybox ash
[ -z "$NOCLEAR" ] && exec env -i NOCLEAR=1 busybox ash "$0"
unset NOCLEAR
HOME=/root
TERM=$TERM
LANG=C
LC_ALL=C
PS1='\u:\w$ '
PATH=/usr/sbin:/usr/bin:/bin:/sbin
export PATH HOME TERM PS1 LANG LC_ALL
busybox mount -t proc none /proc
busybox ash -l
EOF

chmod 755 init
chmod 755 shell.sh

```


### Installing the Cross Compiler

Download and install a static cross-toolchain

```shell

wget -c https://musl.cc/i686-linux-musl-cross.tgz
tar xf i686-linux-musl-cross.tgz
mv i686-linux-musl-cross cross-tools

```

### Musl Dynamic Linker  (ld-musl-i386.so.1)

Copy the musl dinamyc linker to `/lib/` so we can execute dynamic programs

```shell  
  cp -a /cross-tools/i686-linux-musl/lib/libc.so /lib/
  cp -a /cross-tools/i686-linux-musl/lib/ld-musl-i386.so.1 /lib/
```

### GNU Make (static)

We need make to build everything

```shell

  LDFLAGS="-static" ./configure --host=i686-linux-musl --prefix= \
    --disable-dependency-tracking

```    

we compile the package and install make to /cross-tools/bin

```shell

  ./build.sh
  cp make /static/bin/

```

# GNU Tar (static)

We configure GNU TAR using the following command:

```shell
  LDFLAGS="-static" FORCE_UNSAFE_CONFIGURE=1 ./configure \
    --host=i686-linux-musl --prefix=
```

then we build and install the tar binary

```shell
  make
  cp src/tar /static/bin/
```


## 2. Build LFS tools

### Binutils and GCC


Binutils and GCC build just fine

### Linux Headers


We now build the linux headers:

```shell

  make CC="$CC" HOSTCC="$HOSTCC" mrproper headers

```

Install the headers.

```shell

  find usr/include -type f ! -name '*.h' -delete
  cp -rv usr/include $LFS/usr

```

### Glibc


**Build Dependencies:** Gawk, Bison and Python

### Bison


**Build Dependencies:** m4

