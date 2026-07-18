# Portable TCC with Musl Libc

This guide will compile a static toolchain based on tcc and musl that creates static executables

```
TOP=$PWD
TOOLCHAIN=$PWD/toolchain/
export PATH="$TOOLCHAIN/bin:$PATH"

mkdir -p $TOOLCHAIN/bin $TOOLCHAIN/libexec
ln -s . $TOOLCHAIN/usr
```

Configure and build the tcc executable


```bash
tar xf $HOME/sources/tinycc-fada98b.tar.gz -C $TOP
mkdir -p $TOP/build-tcc; cd $TOP/build-tcc
CC="gcc -static --static" ../tinycc-fada98b/configure --config-musl \
  --prefix="." --libpaths="./lib" \
  --crtprefix="./lib" \
  --sysincludepaths="./include" \
  --tccdir="./lib"
  
make tcc
```

Install the tcc executable:


```bahs
cp ./tcc $TOOLCHAIN/libexec/
```
Create a wrapper:

```bash
cat > $TOOLCHAIN/bin/musl-tcc << "EOF"
#!/bin/sh
echo "==> $0 $*" >> /tmp/musl-tcc.log
workdir=$(pwd)

HERE="$(cd "$(dirname $0)/.." && pwd)/"

cd $workdir


# Verifichiamo se nella riga di comando sono presenti flag che disattivano il linking
IS_COMPILE_ONLY=0
for arg in "$@"; do
   case "$arg" in
     -c|-E|-S|-v)
         IS_COMPILE_ONLY=1
         ;;
     -ar)
        exec "$HERE/libexec/tcc" "$@"
        ;;
#    -print-search-dirs)
#    exec  "$HERE/libexec/tcc" "$@"
#    ;;
   esac
done

# Se NON è una compilazione parziale, aggiungiamo gli oggetti di runtime e le librerie
if [ $IS_COMPILE_ONLY -eq 0 ]; then
    STARTUP_FILES="$HERE/lib/crt1.o $HERE/lib/crti.o"
    LIBS="-lc -ltcc1 $HERE/lib/crtn.o"
fi


# exec "$HERE/libexec/tcc" "$@" -I"$HERE/include" -B"$HERE/lib" -L"$HERE/lib" 
exec "$HERE/libexec/tcc"  \
  -static \
  -nostdlib \
  -nostdinc \
  -B"$HERE/lib" \
  -L"$HERE/lib" \
  -isystem"$HERE/include" \
  -L"$HERE/lib" \
  $STARTUP_FILES \
  "$@" \
  $LIBS
  
EOF

chmod +x $TOOLCHAIN/bin/musl-tcc
```

## Musl Libc

### Prepare the sources

Extract the sources of musl libc

```bash
tar xf $HOME/sources/musl-1.2.5.tar.gz -C $TOP
cd $TOP/musl-1.2.5
```

Patch the sources in order to bootstrap the library

```bash
grep -rl '@PLT' src/ | xargs sed -i 's/@PLT//g'
mkdir -p EXCLUDE/math/x86_64/
mv -v src/complex/ EXCLUDE/
mv -v src/math/x86_64/*.c EXCLUDE/math/x86_64/

```

### build the musl libc

```bash
mkdir $TOP/build-musl; cd $TOP/build-musl

CC="musl-tcc" AR="musl-tcc -ar" RANLIB="ranlib" ../musl-1.2.5/configure \
  --prefix=/usr \
  --disable-shared

make
make install DESTDIR=$TOOLCHAIN
```

## Compile libtcc1.a

```bash
cd $TOP/build-tcc
make C_INCLUDE_PATH=$C_INCLUDE_PATH:$TOOLCHAIN/include/:$PWD/../tinycc-fada98b/include
make install DESTDIR=$TOOLCHAIN
```

## Install linux headers
```bash
tar xf $HOME/sources/linux-6.16.1.tar.xz -C $TOP
cd $TOP/linux-6.16.1

sed -i.orig 's/-Wp,-MMD,\$(depfile)/-MD -MF $(depfile)/g' scripts/Makefile.build scripts/Makefile.host
sed -i.orig 's/-Wp,-MD,\$(depfile)/-MD -MF $(depfile)/g' scripts/Makefile.build scripts/Makefile.host
make mrproper HOSTCC="musl-tcc" CC="musl-tcc"
ARCH=x86_64 make headers HOSTCC="musl-tcc" CC="musl-tcc"
find usr/include -type f ! -name '*.h' -delete
cp -rv usr/include $TOOLCHAIN/include
```

# Test Programs

## Build Hello World

Create a test hello.c and compile it with musl-tcc

```bash
cat > hello.c << "EOF" 
#include <stdio.h>

int main(){
printf("Hello World!\n");
return 0;}
EOF
```

```bash
musl-tcc hello.c
```

run `ldd` and `file` on `a.out`. They should say:

> not a dynamic executable

> a.out: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped

## Build Binutils

We successfully built binutils using the wrapper:

```bash
tar xf $HOME/sources/binutils-2.45.tar.xz -C $TOP
mkdir -p $TOP/build-binutils; cd $TOP/build-binutils

CC=musl-tcc ../binutils-2.45/configure --prefix=$HOME/tools --disable-gprofng \
  --disable-multilib --disable-nls --without-zstd --disable-shared
  
make  
```

## Bash

```bash
tar xf $HOME/sources/bash-5.3.32.tar.xz -C $TOP
mkdir $TOP/build-bash; cd $TOP/build-bash
CC="musl-tcc" ../bash-5.2.32/configure --without-bash-malloc

make
```

## mksh

mksh is a posix shell with tab-completion (unlike dash)

```bash
tar xf $HOME/sources/mksh-R59c.tgz -C $TOP
cd $TOP/mksh
CC="musl-tcc" sh ./Build.sh
```

## sbase

sbase is a busybox-like program that contains core utilities. Run `make sbase-box` to compile the single executable variant.
To install it you have to use `sbase-box [-i path] [command]`

```bash
git clone --depth 1 git://git.suckless.org/sbase $TOP/sbase
cd $TOP/sbase
CC="musl-tcc" make sbase-box
```


