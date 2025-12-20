#!/bin/bash
# LFS Phase 2: Temporary Tools Build
# Chapter 6 of LFS 12.4
# These tools will be used in the chroot environment

set -e

export LFS=/mnt/lfs

# Detect architecture and set LFS_TGT accordingly
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        export LFS_TGT=x86_64-lfs-linux-gnu
        ;;
    aarch64|arm64)
        export LFS_TGT=aarch64-lfs-linux-gnu
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

export PATH=$LFS/tools/bin:$PATH
export CONFIG_SITE=$LFS/usr/share/config.site

SOURCES=$LFS/sources
BUILD_DIR=$LFS/build

mkdir -p $BUILD_DIR
cd $BUILD_DIR

echo "=== LFS Phase 2: Temporary Tools ==="
echo "Host Architecture: $ARCH"
echo "LFS=$LFS"
echo "LFS_TGT=$LFS_TGT"
echo ""

#######################################
# 6.2 M4
#######################################
build_m4() {
    echo "=== Building M4 ==="
    cd $SOURCES

    rm -rf m4-1.4.20
    tar xf m4-1.4.20.tar.xz
    cd m4-1.4.20

    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf m4-1.4.20

    echo "M4: DONE"
}

#######################################
# 6.3 Ncurses
#######################################
build_ncurses() {
    echo "=== Building Ncurses ==="
    cd $SOURCES

    rm -rf ncurses-6.5
    tar xf ncurses-6.5.tar.gz
    cd ncurses-6.5

    # Build tic for host
    mkdir -p build
    pushd build
        ../configure
        make -C include
        make -C progs tic
    popd

    ./configure --prefix=/usr                \
                --host=$LFS_TGT              \
                --build=$(./config.guess)    \
                --mandir=/usr/share/man      \
                --with-manpage-format=normal \
                --with-shared                \
                --without-normal             \
                --with-cxx-shared            \
                --without-debug              \
                --without-ada                \
                --disable-stripping

    make -j$(nproc)
    make DESTDIR=$LFS TIC_PATH=$(pwd)/build/progs/tic install
    ln -sfv libncursesw.so $LFS/usr/lib/libncurses.so
    sed -e 's/^#if.*XOPEN.*$/#if 1/' \
        -i $LFS/usr/include/curses.h

    cd $SOURCES
    rm -rf ncurses-6.5

    echo "Ncurses: DONE"
}

#######################################
# 6.4 Bash
#######################################
build_bash() {
    echo "=== Building Bash ==="
    cd $SOURCES

    rm -rf bash-5.2.37
    tar xf bash-5.2.37.tar.gz
    cd bash-5.2.37

    ./configure --prefix=/usr                      \
                --build=$(sh support/config.guess) \
                --host=$LFS_TGT                    \
                --without-bash-malloc              \
                bash_cv_strtold_broken=no

    make -j$(nproc)
    make DESTDIR=$LFS install

    # Make bash the default shell (in chroot it will be /bin/sh)
    mkdir -pv $LFS/bin
    ln -sfv ../usr/bin/bash $LFS/bin/sh

    cd $SOURCES
    rm -rf bash-5.2.37

    echo "Bash: DONE"
}

#######################################
# 6.5 Coreutils
#######################################
build_coreutils() {
    echo "=== Building Coreutils ==="
    cd $SOURCES

    rm -rf coreutils-9.5
    tar xf coreutils-9.5.tar.xz
    cd coreutils-9.5

    ./configure --prefix=/usr                     \
                --host=$LFS_TGT                   \
                --build=$(build-aux/config.guess) \
                --enable-install-program=hostname \
                --enable-no-install-program=kill,uptime

    make -j$(nproc)
    make DESTDIR=$LFS install

    # Move programs to proper locations
    mv -v $LFS/usr/bin/chroot              $LFS/usr/sbin
    mkdir -pv $LFS/usr/share/man/man8
    mv -v $LFS/usr/share/man/man1/chroot.1 $LFS/usr/share/man/man8/chroot.8
    sed -i 's/"1"/"8"/'                    $LFS/usr/share/man/man8/chroot.8

    cd $SOURCES
    rm -rf coreutils-9.5

    echo "Coreutils: DONE"
}

#######################################
# 6.6 Diffutils
#######################################
build_diffutils() {
    echo "=== Building Diffutils ==="
    cd $SOURCES

    rm -rf diffutils-3.10
    tar xf diffutils-3.10.tar.xz
    cd diffutils-3.10

    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(./build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf diffutils-3.10

    echo "Diffutils: DONE"
}

#######################################
# 6.7 File
#######################################
build_file() {
    echo "=== Building File ==="
    cd $SOURCES

    rm -rf file-5.45
    tar xf file-5.45.tar.gz
    cd file-5.45

    # Build file for host first
    mkdir -p build
    pushd build
        ../configure --disable-bzlib      \
                     --disable-libseccomp \
                     --disable-xzlib      \
                     --disable-zlib
        make
    popd

    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(./config.guess)

    make FILE_COMPILE=$(pwd)/build/src/file -j$(nproc)
    make DESTDIR=$LFS install

    # Remove libtool archive
    rm -v $LFS/usr/lib/libmagic.la

    cd $SOURCES
    rm -rf file-5.45

    echo "File: DONE"
}

#######################################
# 6.8 Findutils
#######################################
build_findutils() {
    echo "=== Building Findutils ==="
    cd $SOURCES

    rm -rf findutils-4.10.0
    tar xf findutils-4.10.0.tar.xz
    cd findutils-4.10.0

    ./configure --prefix=/usr                   \
                --localstatedir=/var/lib/locate \
                --host=$LFS_TGT                 \
                --build=$(build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf findutils-4.10.0

    echo "Findutils: DONE"
}

#######################################
# 6.9 Gawk
#######################################
build_gawk() {
    echo "=== Building Gawk ==="
    cd $SOURCES

    rm -rf gawk-5.3.1
    tar xf gawk-5.3.1.tar.xz
    cd gawk-5.3.1

    # Ensure unneeded files are not installed
    sed -i 's/extras//' Makefile.in

    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf gawk-5.3.1

    echo "Gawk: DONE"
}

#######################################
# 6.10 Grep
#######################################
build_grep() {
    echo "=== Building Grep ==="
    cd $SOURCES

    rm -rf grep-3.11
    tar xf grep-3.11.tar.xz
    cd grep-3.11

    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(./build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf grep-3.11

    echo "Grep: DONE"
}

#######################################
# 6.11 Gzip
#######################################
build_gzip() {
    echo "=== Building Gzip ==="
    cd $SOURCES

    rm -rf gzip-1.13
    tar xf gzip-1.13.tar.xz
    cd gzip-1.13

    ./configure --prefix=/usr \
                --host=$LFS_TGT

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf gzip-1.13

    echo "Gzip: DONE"
}

#######################################
# 6.12 Make
#######################################
build_make() {
    echo "=== Building Make ==="
    cd $SOURCES

    rm -rf make-4.4.1
    tar xf make-4.4.1.tar.gz
    cd make-4.4.1

    ./configure --prefix=/usr   \
                --without-guile \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf make-4.4.1

    echo "Make: DONE"
}

#######################################
# 6.13 Patch
#######################################
build_patch() {
    echo "=== Building Patch ==="
    cd $SOURCES

    rm -rf patch-2.7.6
    tar xf patch-2.7.6.tar.xz
    cd patch-2.7.6

    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf patch-2.7.6

    echo "Patch: DONE"
}

#######################################
# 6.14 Sed
#######################################
build_sed() {
    echo "=== Building Sed ==="
    cd $SOURCES

    rm -rf sed-4.9
    tar xf sed-4.9.tar.xz
    cd sed-4.9

    ./configure --prefix=/usr   \
                --host=$LFS_TGT \
                --build=$(./build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf sed-4.9

    echo "Sed: DONE"
}

#######################################
# 6.15 Tar
#######################################
build_tar() {
    echo "=== Building Tar ==="
    cd $SOURCES

    rm -rf tar-1.35
    tar xf tar-1.35.tar.xz
    cd tar-1.35

    ./configure --prefix=/usr                     \
                --host=$LFS_TGT                   \
                --build=$(build-aux/config.guess)

    make -j$(nproc)
    make DESTDIR=$LFS install

    cd $SOURCES
    rm -rf tar-1.35

    echo "Tar: DONE"
}

#######################################
# 6.16 Xz
#######################################
build_xz() {
    echo "=== Building Xz ==="
    cd $SOURCES

    rm -rf xz-5.6.3
    tar xf xz-5.6.3.tar.xz
    cd xz-5.6.3

    ./configure --prefix=/usr                     \
                --host=$LFS_TGT                   \
                --build=$(build-aux/config.guess) \
                --disable-static                  \
                --docdir=/usr/share/doc/xz-5.6.3

    make -j$(nproc)
    make DESTDIR=$LFS install

    # Remove libtool archive
    rm -v $LFS/usr/lib/liblzma.la

    cd $SOURCES
    rm -rf xz-5.6.3

    echo "Xz: DONE"
}

#######################################
# 6.17 Binutils Pass 2
#######################################
build_binutils_pass2() {
    echo "=== Building Binutils Pass 2 ==="
    cd $SOURCES

    rm -rf binutils-2.44
    tar xf binutils-2.44.tar.xz
    cd binutils-2.44

    # Create separate build directory
    sed '6009s/$add_dir//' -i ltmain.sh

    mkdir -p build && cd build

    ../configure                   \
        --prefix=/usr              \
        --build=$(../config.guess) \
        --host=$LFS_TGT            \
        --disable-nls              \
        --enable-shared            \
        --enable-gprofng=no        \
        --disable-werror           \
        --enable-64-bit-bfd        \
        --enable-new-dtags         \
        --enable-default-hash-style=gnu

    make -j$(nproc)
    make DESTDIR=$LFS install

    # Remove libtool archives
    rm -v $LFS/usr/lib/lib{bfd,ctf,ctf-nobfd,opcodes,sframe}.{a,la}

    cd $SOURCES
    rm -rf binutils-2.44

    echo "Binutils Pass 2: DONE"
}

#######################################
# 6.18 GCC Pass 2
#######################################
build_gcc_pass2() {
    echo "=== Building GCC Pass 2 ==="
    cd $SOURCES

    rm -rf gcc-14.2.0
    tar xf gcc-14.2.0.tar.xz
    cd gcc-14.2.0

    # Extract and link dependencies
    tar -xf ../mpfr-4.2.1.tar.xz
    mv -v mpfr-4.2.1 mpfr
    tar -xf ../gmp-6.3.0.tar.xz
    mv -v gmp-6.3.0 gmp
    tar -xf ../mpc-1.3.1.tar.gz
    mv -v mpc-1.3.1 mpc

    # Architecture-specific fix
    case $(uname -m) in
        x86_64)
            sed -e '/m64=/s/lib64/lib/' \
                -i.orig gcc/config/i386/t-linux64
        ;;
    esac

    # Workaround for libgcc issue
    sed '/thread_header =/s/@.*@/gthr-posix.h/' \
        -i libgcc/Makefile.in libstdc++-v3/include/Makefile.in

    mkdir -p build && cd build

    ../configure                                       \
        --build=$(../config.guess)                     \
        --host=$LFS_TGT                                \
        --target=$LFS_TGT                              \
        LDFLAGS_FOR_TARGET=-L$PWD/$LFS_TGT/libgcc      \
        --prefix=/usr                                  \
        --with-build-sysroot=$LFS                      \
        --enable-default-pie                           \
        --enable-default-ssp                           \
        --disable-nls                                  \
        --disable-multilib                             \
        --disable-libatomic                            \
        --disable-libgomp                              \
        --disable-libquadmath                          \
        --disable-libsanitizer                         \
        --disable-libssp                               \
        --disable-libvtv                               \
        --enable-languages=c,c++

    make -j$(nproc)
    make DESTDIR=$LFS install

    # Create cc symlink
    ln -sv gcc $LFS/usr/bin/cc

    cd $SOURCES
    rm -rf gcc-14.2.0

    echo "GCC Pass 2: DONE"
}

#######################################
# Main
#######################################

echo "Starting Phase 2 build..."
echo "This will take 30-60 minutes"
echo ""

build_m4
build_ncurses
build_bash
build_coreutils
build_diffutils
build_file
build_findutils
build_gawk
build_grep
build_gzip
build_make
build_patch
build_sed
build_tar
build_xz
build_binutils_pass2
build_gcc_pass2

echo ""
echo "=== Phase 2 Complete ==="
echo "Temporary tools installed to: $LFS/usr"
echo ""
echo "Verify with:"
echo "  ls $LFS/usr/bin/"
echo "  $LFS/usr/bin/bash --version"
