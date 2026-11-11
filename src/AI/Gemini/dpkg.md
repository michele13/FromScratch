# DPKG Notes

## do I need to install the whole package or I can just install certain programs?

You can install only parts of it. dpkg's build system doesn't offer a clean "install just these programs" option, but you have a few practical routes.

**What dpkg actually contains**

The source builds several executables:
- `dpkg`: the core installer (what you need for actually installing, removing, and querying packages)
- `dpkg-deb`: builds and unpacks `.deb` files (needed to create your own packages, and `dpkg` calls it internally)
- `dpkg-query`: queries the package database
- `dpkg-split`: splits and merges large packages (rarely needed)
- `dpkg-divert`, `dpkg-statoverride`, `dpkg-trigger`, `dpkg-realpath`: helper tools
- `update-alternatives`: manages alternative command symlinks
- `start-stop-daemon`: init-script helper
- The Perl-based `dpkg-dev` scripts (`dpkg-buildpackage`, `dpkg-source`, `dpkg-shlibdeps`, `dpkg-gencontrol`, etc.) for building packages

**The practical advice**

1. **Install everything the normal way.** `make install` into your LFS system is the simplest and safest option. The whole thing is small, and several pieces depend on each other: `dpkg` expects `dpkg-deb`, `dpkg-query`, and `dpkg-split` to be present, and maintainer scripts commonly call `update-alternatives`, `dpkg-divert`, and `dpkg-statoverride`.

2. **If you want to trim it**, you can configure out some components:
   - `--without-dpkg-deb`, `--disable-start-stop-daemon`, `--disable-update-alternatives`, `--disable-dselect`, and `--disable-devel-docs` exist in various versions. Run `./configure --help` on your specific version to see what's available, since options change between releases.
   - `--disable-dselect` and `--disable-nls` are common choices for a minimal system.
   - The Perl dev tools (`dpkg-dev` scripts) are controlled by the build, but if you never build `.deb` files on that machine, you can simply not use them, or delete them after installation.

3. **Manual cherry-picking** (build everything, then copy only what you want) works but is fragile. You'd need to remember the config files, the `/var/lib/dpkg` database layout, and the shared library `libdpkg` if it's used.

**Things to watch for**

- The database directory `/var/lib/dpkg` must exist, along with files like `status` and `available`. Create them manually if the install doesn't:
  ```
  mkdir -p /var/lib/dpkg/{info,updates,alternatives}
  touch /var/lib/dpkg/{status,available}
  ```
- Perl is required if you keep the dpkg-dev scripts, and `dpkg` itself needs a few build dependencies (ncurses, zlib, xz/liblzma, bzip2, libmd, and optionally zstd).
- Use `DESTDIR` if you want to inspect the installed file list before committing it to the live system: `make install DESTDIR=/tmp/dpkg-staging`.

**Bottom line:** for an LFS package manager setup, install the full set of core tools (`dpkg`, `dpkg-deb`, `dpkg-query`, `dpkg-divert`, `dpkg-statoverride`, `update-alternatives`) and trim optional extras like dselect, NLS, and docs if you want to save space. You'll probably also want `dpkg-dev` if you plan to build your own `.deb` packages.

Are you planning to build your own `.deb` packages for LFS, or just use dpkg to track installs? That changes which pieces matter most.


## why would i want dpkg-dev?

You'd want it only if you're going to **create** `.deb` packages on that machine. If you're just installing or tracking existing ones, you don't need it.

**What it's for**

`dpkg-dev` is the toolset for building packages: `dpkg-buildpackage` drives the whole build, `dpkg-source` packs and unpacks source packages, `dpkg-gencontrol` generates the control file for each binary package, `dpkg-shlibdeps` figures out shared library dependencies automatically, and `dpkg-genchanges`, `dpkg-parsechangelog` and similar tools handle metadata.

**Why it matters for LFS specifically**

LFS has no packages by default, so if you want dpkg to manage your system, you have to build the `.deb` files yourself. There are two ways to do that:

1. **Use the full Debian-style workflow** (a `debian/` directory with `control`, `rules`, `changelog`, then `dpkg-buildpackage`). This needs `dpkg-dev`, plus usually `debhelper` and `fakeroot`, which are separate packages you'd also have to build.

2. **Use the lightweight approach.** Run `make install DESTDIR=/tmp/pkg`, write a `DEBIAN/control` file by hand inside that directory, then run `dpkg-deb --build /tmp/pkg`. This only needs `dpkg-deb`, which is part of core dpkg, so no `dpkg-dev` required.

Most people doing LFS with dpkg use the second approach, since the first drags in a lot of Debian tooling that assumes a Debian-like environment. The trade-off is that you write control files yourself and get no automatic dependency detection.

**When to skip it**

If you're only tracking installs, or you build packages elsewhere (say, on a Debian machine or in a chroot) and just install them on the LFS system, `dpkg` alone is enough.

## I Want the lightweight approach

Good choice for LFS. Here's the workflow, step by step.

**1. Build and stage into a fake root**

```
./configure --prefix=/usr
make
make install DESTDIR=/tmp/pkg/foo-1.2.3
```

Everything the package installs lands under `/tmp/pkg/foo-1.2.3` instead of your live system. Use one staging directory per package and keep the version in the name.

**2. Write the control file**

```
mkdir -p /tmp/pkg/foo-1.2.3/DEBIAN
cat > /tmp/pkg/foo-1.2.3/DEBIAN/control << EOF
Package: foo
Version: 1.2.3-1
Architecture: amd64
Maintainer: Your Name <you@example.com>
Installed-Size: $(du -sk /tmp/pkg/foo-1.2.3 --exclude=DEBIAN | cut -f1)
Depends: libbar (>= 2.0)
Description: Short one-line description
 Optional longer description, each line indented by one space.
EOF
```

The required fields are `Package`, `Version`, `Architecture`, `Maintainer`, and `Description`. `Depends` is optional but worth filling in by hand, since nothing will detect dependencies for you. Use `Architecture: all` for architecture-independent packages.

**3. Clean up the staging tree**

Before packaging, a few things usually need fixing:

- Remove `/usr/share/info/dir`, because it's shared by all packages and will cause file conflicts.
- Remove `.la` files if you don't need them.
- Strip binaries to save space:
  ```
  find /tmp/pkg/foo-1.2.3 -type f -exec file {} + | grep ELF | cut -d: -f1 | xargs -r strip --strip-unneeded
  ```
- Gzip man pages if your LFS build doesn't already do it.
- Don't package `/etc` config files carelessly. See the conffiles note below.

**4. Build the package**

```
dpkg-deb --build --root-owner-group /tmp/pkg/foo-1.2.3 /tmp/pkg/foo_1.2.3-1_amd64.deb
```

`--root-owner-group` makes everything in the archive owned by root, which avoids needing `fakeroot`. Without it, files would be owned by whoever ran the build.

**5. Install and verify**

```
dpkg -i /tmp/pkg/foo_1.2.3-1_amd64.deb
dpkg -L foo     # list installed files
dpkg -s foo     # show status
```

**Optional extras**

- **conffiles:** if the package ships files in `/etc` that users will edit, list them (one absolute path per line) in `DEBIAN/conffiles`. dpkg then won't overwrite local changes on upgrade.
- **Maintainer scripts:** `DEBIAN/postinst`, `prerm`, `postrm`, and `preinst` are shell scripts, which must be executable (`chmod 755`). Typical uses are running `ldconfig` after installing libraries or updating caches.
- **Library packages:** add `ldconfig` to `postinst` and `postrm`, or dpkg will install the libraries but the dynamic linker won't see them until you run it manually.

**A small helper script**

Since steps 2 to 4 repeat for every package, you'll want to wrap them in a script. A minimal version takes the name, version, and dependencies as arguments, generates the control file, strips binaries, and runs `dpkg-deb`. That saves a lot of typing across the hundreds of packages in an LFS build.

**One caveat for the initial LFS packages**

The packages from the LFS book that were installed before dpkg existed (glibc, gcc, coreutils, and so on) aren't in dpkg's database. Dpkg doesn't know they exist, so dependencies on them will fail unless you either rebuild them as `.deb` files or create dummy packages that declare them as installed, or use `dpkg -i --force-depends` for those cases.

Do you want me to write that helper script for you?