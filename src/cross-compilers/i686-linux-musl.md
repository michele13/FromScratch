# i686-linux-musl

This work is based on [musl-cross-make's litecross](https://github.com/richfelker/musl-cross-make/blob/master/litecross/Makefile)

## Preparing for the build

### Setting environment variables

Set the following environment variables

```bash
    KERNEL_ARCH="x86"
    TARGET="i686-linux-musl"
    DOWNLOADS=${PWD}/downloads
    SOURCES=${PWD}/sources
    OUTPUT="${PWD}/output/${TARGET}"
    HOST=$(echo ${MACHTYPE} | sed "s/-[^-]*/-cross/")
    MAKEFLAGS="-j$(nproc)"
    PATH="${OUTPUT}/bin:${PATH}"
    GCC_CONFIG_FOR_TARGET=""
    COMMON_CONFIG=""

    export PATH OUTPUT KERNEL_ARCH TARGET HOST MAKEFLAGS
```

if we have a musl cross-compiler available we can build our toolchain statically!

```bash
_cc="gcc"
_cxx="g++"
musl_cxx="$(which -- $(uname -m)-linux-musl-g++)"
musl_cc="$(which -- $(uname -m)-linux-musl-gcc)"


if [ -n "$musl_cxx" ]; then
   _cc="$musl_cc -static --static" 
   _cxx="$musl_cxx -static --static"
fi
```


### Download and extract the sources

Set the version of the software that we want to download:

```bash
	binutils_ver=2.45
	gcc_ver=15.2.0
	musl_ver=1.2.5
	gmp_ver=6.3.0
	mpc_ver=1.3.1
	mpfr_ver=4.2.2
	linux_ver=6.16.1
```
Download the source tarballs:

```bash
    mkdir -p ${SOURCES} ${DOWNLOADS}; cd ${DOWNLOADS}
    if [ ! -f ${DOWNLOADS}/.dl_complete ]; then
	wget -c https://ftpmirror.gnu.org/binutils/binutils-$binutils_ver.tar.xz
	wget -c https://ftpmirror.gnu.org/gcc/gcc-$gcc_ver/gcc-$gcc_ver.tar.xz
	wget -c https://musl.libc.org/releases/musl-$musl_ver.tar.gz
	wget -c https://ftpmirror.gnu.org/gmp/gmp-$gmp_ver.tar.xz
	wget -c https://ftpmirror.gnu.org/mpc/mpc-$mpc_ver.tar.gz
	wget -c https://ftpmirror.gnu.org/mpfr/mpfr-$mpfr_ver.tar.xz
	wget -c https://www.kernel.org/pub/linux/kernel/v6.x/linux-$linux_ver.tar.xz
    fi
```

If the download went fine we will create a file called `.dl_complete` so that we will not run wget again

```bash
	touch .dl_complete
```

Extract the sources:

```bash
    for f in *.tar*; do tar xf $f -C ${SOURCES} ; done
```

## Create directory structure

```bash
    mkdir -p ${OUTPUT}/${TARGET}
    ln -s . ${OUTPUT}/${TARGET}/usr || true
```


## Linux Headers

Enter in the linux kernel source tree and type:

```bash
    cd ${SOURCES}/linux-$linux_ver
    make mrproper
    ARCH=${KERNEL_ARCH} make headers
    find usr/include -type f ! -name '*.h' -delete
    cp -rv usr/include ${OUTPUT}/${TARGET}
```

## Binutils

Create a build directory for binutils

```bash
    mkdir -p ${SOURCES}/build-binutils
    cd ${SOURCES}/build-binutils
```
 
Configure Binutils:

```bash
    ../binutils-$binutils_ver/configure --enable-gprofng=no \
        --disable-separate-code \
        --disable-werror \
        --target=${TARGET} --prefix= \
        --libdir=/lib --disable-multilib \
	    --with-sysroot=/${TARGET} \
	    --enable-deterministic-archives \
        --build=${HOST} --host=${HOST} \
        ${COMMON_CONFIG} CC="${_cc}" CXX="${_cxx}"
```

Build and install the package:

```bash
    make
    make install-strip DESTDIR=${OUTPUT}
```

## GCC (Core)

Enter in the source directory of GCC and prepare GMP, MPFR and MPC

```bash
    cd ${SOURCES}/gcc-$gcc_ver
    ln -sf ../gmp-$gmp_ver gmp
    ln -sf ../mpfr-$mpfr_ver mpfr
    ln -sf ../mpc-$mpc_ver mpc
```
Create a build directory for gcc

```bash
    mkdir -p ${SOURCES}/build-gcc
    cd ${SOURCES}/build-gcc
```

Configure GCC:

```bash
    ../gcc-$gcc_ver/configure --target=${TARGET} \
        --host=${HOST} --build=${HOST} \
        --enable-languages=c,c++ \
        --disable-bootstrap \
        --disable-assembly \
        --disable-werror \
        --target=${TARGET} --prefix= \
        --libdir=/lib --disable-multilib \
        --with-sysroot=/${TARGET} \
        --with-build-sysroot=${OUTPUT}/${TARGET} \
        --enable-tls \
        --disable-libmudflap --disable-libsanitizer \
        --disable-gnu-indirect-function \
        --disable-libmpx \
        --enable-initfini-array \
        --enable-libstdcxx-time=rt \
        ${GCC_CONFIG_FOR_TARGET} \
        ${COMMON_CONFIG} CC="${_cc}" CXX="${_cxx}"
```

Build the core of GCC

```bash
    make all-gcc 
    make install-strip-gcc DESTDIR=${OUTPUT}
```

Leave the build directory intact. We will use it later

## Musl Headers

Create a build directory for musl

```bash
    mkdir -p ${SOURCES}/build-musl
    cd ${SOURCES}/build-musl
```


Configure and install the headers

```bash
    ../musl-$musl_ver/configure --prefix=/usr \
        --host=$TARGET --disable-nls --disable-werror
    make DESTDIR=${OUTPUT}/${TARGET} install-headers
```

Keep the source directory but remove the build directory

```bash
    cd ${SOURCES}
    rm -rf build-musl
```

## GCC (libgcc.a)

Build and install libgcc.a

```bash
    cd ${SOURCES}/build-gcc
    make all-target-libgcc enable_shared=no
    make install-strip-target-libgcc DESTDIR=${OUTPUT}
```

Leave the build directory intact. We will use it later

## Musl libc

Create a build directory for musl

```bash
    mkdir -p ${SOURCES}/build-musl
    cd ${SOURCES}/build-musl
```

Configure, build and install Musl libc

```bash
    ../musl-$musl_ver/configure --prefix=/usr \
        --host=$TARGET --disable-nls --disable-werror
    make
    make install DESTDIR=${OUTPUT}/${TARGET}
```

## GCC (Final)

Now we will finish building GCC. We will first rebuild **libgcc**, this will provide us a shared library.

Enter in the build directory of GCC and clean the build directory of **ligbcc**:

```bash
    cd ${SOURCES}/build-gcc
    make -C ${TARGET}/libgcc distclean
```
We can now rebuild the support library of the compiler:

```bash
    make all-target-libgcc
    make install-strip-target-libgcc DESTDIR=${OUTPUT}
```
Finish the build of GCC and install it:

```bash
    make
    make install-strip DESTDIR=${OUTPUT}
```

We should now have a working cross-compiler!