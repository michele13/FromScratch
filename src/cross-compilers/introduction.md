# Introduction to cross-compilers

## Dependencies

- cross-toolchains depends on:
  - Kernel Headers
  - Binutils
  - GCC which depends on Libc and Kernel Headers
  - Libc (depends on libgcc, part of GCC)
    - libgcc depends on libc headers
        - libc headers

## See Also

- <https://preshing.com/20141119/how-to-build-a-gcc-cross-compiler/>
- <https://github.com/firasuke/mussel>
        

## General build instructions for a package

- Extract the tarball
- Create a build directory and enter into it
- Configure the package and build it (`../software_src/configure --options; make; make install DESTDIR=${OUTPUT}`)
- Remove the sources and the build directory