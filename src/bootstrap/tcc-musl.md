# Bootstrap Musl Libc with TCC

In this page i will compile musl libc for x86_64 using TCC (mob branch). Do not try to run this file using blaze

## Compile TCC

```bash
../tinycc-fada98b/configure --prefix=$HOME/tools/ \
  --sysroot=$HOME/tools/sysroot \
  --config-musl --triplet=x86_64-linux-musl
  
make && make install
```

copy `libtcc1.a` to `$HOME/tools/sysroot/lib/`

```bash
mkdir -p $HOME/tools/sysroot/lib/
cp libtcc.a $HOME/tools/sysroot/lib/
```


## Prepare the sources of Musl libc

Extract the sources of musl libc

```bash
tar xf $HOME/sources/musl-1.2.5.tar.gz
cd musl-1.2.5
```

Patch the sources in order to bootstrap the library

```bash
grep -rl '@PLT' src/ | xargs sed -i 's/@PLT//g'
mkdir -p EXCLUDE/math/x86_64/
mv -v src/complex/ EXCLUDE/
mv -v src/math/x86_64/*.c EXCLUDE/math/x86_64/

```



## Compile Musl Libc

```bash
mkdir ../build-musl; cd ../build-musl

CC="tcc" AR="tcc -ar" RANLIB="ranlib" ./configure \
  --prefix=$HOME/tools/sysroot \
  --disable-shared

make
make install
```

## Write the wrapper

Create the script `musl-tcc` to compile programs and make it executable

```bash
cat > $HOME/tools/bin/musl-tcc << "EOF"
#!/bin/sh

# Definisci il percorso assoluto del tuo sysroot dove hai installato musl
SYSROOT="/home/michele/tools/sysroot"

# Inizializziamo le variabili per i flag condizionali
STARTUP_FILES=""
LIBS=""

# Verifichiamo se nella riga di comando sono presenti flag che disattivano il linking
IS_COMPILE_ONLY=0
for arg in "$@"; do
    case "$arg" in
        -c|-E|-S|-v)
            IS_COMPILE_ONLY=1
            ;;
    esac
done

# Se NON è una compilazione parziale, aggiungiamo gli oggetti di runtime e le librerie
if [ $IS_COMPILE_ONLY -eq 0 ]; then
    STARTUP_FILES="$SYSROOT/lib/crt1.o $SYSROOT/lib/crti.o"
    LIBS="-lc -ltcc1 $SYSROOT/lib/crtn.o"
fi

# Esegui il vero TCC iniettando i flag di isolamento e i percorsi di musl
exec tcc \
  -static \
  -nostdinc \
  -nostdlib \
  -isystem "$SYSROOT/include" \
  -B"$SYSROOT/lib" \
  -L"$SYSROOT/lib" \
  $STARTUP_FILES \
  "$@" \
  $LIBS
  
EOF

chmod +x $HOME/tools/bin/musl-tcc
```

# Test

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
CC=musl-tcc ../binutils-2.45/configure --prefix=$HOME/tools --disable-gprofng \
  --disable-multilib --disable-nls --without-zstd --disable-shared
```

## Bash

```bash
CC="musl-tcc" ../bash-5.2.32/configure --without-bash-malloc

make && make install
```

## mksh

```bash

CC="musl-tcc" sh ./Build.sh
```

## Busybox