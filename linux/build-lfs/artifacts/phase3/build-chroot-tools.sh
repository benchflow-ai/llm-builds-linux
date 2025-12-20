#!/bin/bash
# LFS Phase 3: Chroot Environment Setup and Additional Tools
# Chapter 7 of LFS 12.4
# This phase sets up the chroot environment and builds additional temporary tools

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

SOURCES=$LFS/sources

echo "=== LFS Phase 3: Chroot Environment Setup ==="
echo "Host Architecture: $ARCH"
echo "LFS=$LFS"
echo ""

#######################################
# Step 1: Change ownership to root
#######################################
echo "=== Step 1: Changing Ownership ==="
chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
case $ARCH in
    x86_64)
        chown -R root:root $LFS/lib64
        ;;
    aarch64|arm64)
        [ -e $LFS/lib64 ] && chown -R root:root $LFS/lib64
        ;;
esac

#######################################
# Step 2: Prepare Virtual Kernel File Systems
#######################################
echo "=== Step 2: Preparing Virtual Kernel File Systems ==="

# Create mount points
mkdir -pv $LFS/{dev,proc,sys,run}

# Mount /dev
if ! mountpoint -q $LFS/dev; then
    mount -v --bind /dev $LFS/dev
fi

# Mount virtual kernel file systems
if ! mountpoint -q $LFS/dev/pts; then
    mount -vt devpts devpts -o gid=5,mode=0620 $LFS/dev/pts
fi

if ! mountpoint -q $LFS/proc; then
    mount -vt proc proc $LFS/proc
fi

if ! mountpoint -q $LFS/sys; then
    mount -vt sysfs sysfs $LFS/sys
fi

if ! mountpoint -q $LFS/run; then
    mount -vt tmpfs tmpfs $LFS/run
fi

# Handle /dev/shm
if [ -h $LFS/dev/shm ]; then
    install -v -d -m 1777 $LFS$(realpath /dev/shm)
else
    if ! mountpoint -q $LFS/dev/shm; then
        mount -vt tmpfs -o nosuid,nodev tmpfs $LFS/dev/shm
    fi
fi

echo "Virtual kernel file systems mounted successfully"

#######################################
# Step 3: Enter Chroot and Create Directory Structure
#######################################
echo "=== Step 3: Creating Directory Structure in Chroot ==="

# Create script to run inside chroot
cat > $LFS/phase3-chroot.sh << 'CHROOT_EOF'
#!/bin/bash
set -e

echo "=== Inside Chroot Environment ==="

# Create directory structure
mkdir -pv /{boot,home,mnt,opt,srv}
mkdir -pv /etc/{opt,sysconfig}
mkdir -pv /lib/firmware
mkdir -pv /media/{floppy,cdrom}
mkdir -pv /usr/{,local/}{include,src}
mkdir -pv /usr/lib/locale
mkdir -pv /usr/local/{bin,lib,sbin}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -pv /usr/{,local/}share/man/man{1..8}
mkdir -pv /var/{cache,local,log,mail,opt,spool}
mkdir -pv /var/lib/{color,misc,locate}

# Create symbolic links
ln -sfv /run /var/run
ln -sfv /run/lock /var/lock

# Create directories with special permissions
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp

echo "Directory structure created"

#######################################
# Step 4: Create Essential Files and Symlinks
#######################################
echo "=== Creating Essential Files and Symlinks ==="

# Create /etc/mtab symlink
ln -sv /proc/self/mounts /etc/mtab

# Create /etc/hosts
cat > /etc/hosts << EOF
127.0.0.1  localhost $(hostname)
::1        localhost
EOF

# Create /etc/passwd
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/usr/bin/false
daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
nobody:x:65534:65534:Unprivileged User:/dev/null:/usr/bin/false
EOF

# Create /etc/group
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
uuidd:x:80:
wheel:x:97:
users:x:999:
nogroup:x:65534:
EOF

# Initialize log files
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp

echo "Essential files created"

#######################################
# Step 5: Build Gettext (minimal install)
#######################################
echo "=== Building Gettext-0.26 ==="
cd /sources

rm -rf gettext-0.26
tar xf gettext-0.26.tar.xz
cd gettext-0.26

./configure --disable-shared

make -j$(nproc)

# Only install the three programs we need
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /usr/bin

cd /sources
rm -rf gettext-0.26

echo "Gettext: DONE"

#######################################
# Step 6: Build Bison
#######################################
echo "=== Building Bison-3.8.2 ==="
cd /sources

rm -rf bison-3.8.2
tar xf bison-3.8.2.tar.xz
cd bison-3.8.2

./configure --prefix=/usr \
            --docdir=/usr/share/doc/bison-3.8.2

make -j$(nproc)
make install

cd /sources
rm -rf bison-3.8.2

echo "Bison: DONE"

#######################################
# Step 7: Build Perl
#######################################
echo "=== Building Perl-5.42.0 ==="
cd /sources

rm -rf perl-5.42.0
tar xf perl-5.42.0.tar.xz
cd perl-5.42.0

sh Configure -des \
             -D prefix=/usr \
             -D vendorprefix=/usr \
             -D useshrplib \
             -D privlib=/usr/lib/perl5/5.42/core_perl \
             -D archlib=/usr/lib/perl5/5.42/core_perl \
             -D sitelib=/usr/lib/perl5/5.42/site_perl \
             -D sitearch=/usr/lib/perl5/5.42/site_perl \
             -D vendorlib=/usr/lib/perl5/5.42/vendor_perl \
             -D vendorarch=/usr/lib/perl5/5.42/vendor_perl

make -j$(nproc)
make install

cd /sources
rm -rf perl-5.42.0

echo "Perl: DONE"

#######################################
# Step 8: Build Python
#######################################
echo "=== Building Python-3.13.7 ==="
cd /sources

rm -rf Python-3.13.7
tar xf Python-3.13.7.tar.xz
cd Python-3.13.7

./configure --prefix=/usr       \
            --enable-shared     \
            --without-ensurepip \
            --without-static-libpython

make -j$(nproc)
make install

cd /sources
rm -rf Python-3.13.7

echo "Python: DONE"

#######################################
# Step 9: Build Texinfo
#######################################
echo "=== Building Texinfo-7.2 ==="
cd /sources

rm -rf texinfo-7.2
tar xf texinfo-7.2.tar.xz
cd texinfo-7.2

./configure --prefix=/usr

make -j$(nproc)
make install

cd /sources
rm -rf texinfo-7.2

echo "Texinfo: DONE"

#######################################
# Step 10: Build Util-linux
#######################################
echo "=== Building Util-linux-2.41.1 ==="
cd /sources

rm -rf util-linux-2.41.1
tar xf util-linux-2.41.1.tar.xz
cd util-linux-2.41.1

# Create directory for hwclock
mkdir -pv /var/lib/hwclock

./configure --libdir=/usr/lib     \
            --runstatedir=/run    \
            --disable-chfn-chsh   \
            --disable-login       \
            --disable-nologin     \
            --disable-su          \
            --disable-setpriv     \
            --disable-runuser     \
            --disable-pylibmount  \
            --disable-static      \
            --disable-liblastlog2 \
            --without-python      \
            ADJTIME_PATH=/var/lib/hwclock/adjtime \
            --docdir=/usr/share/doc/util-linux-2.41.1

make -j$(nproc)
make install

cd /sources
rm -rf util-linux-2.41.1

echo "Util-linux: DONE"

echo ""
echo "=== Phase 3 Complete ==="
echo "Chroot environment is ready with additional temporary tools"
echo ""

CHROOT_EOF

chmod +x $LFS/phase3-chroot.sh

#######################################
# Execute the chroot script
#######################################
echo "=== Entering Chroot to Build Additional Tools ==="

chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    MAKEFLAGS="-j$(nproc)"      \
    TESTSUITEFLAGS="-j$(nproc)" \
    /bin/bash /phase3-chroot.sh

# Clean up the script
rm -f $LFS/phase3-chroot.sh

echo ""
echo "=== Phase 3 Complete ==="
echo "Additional temporary tools built successfully"
echo "The system is now ready for Phase 4: Full System Build"
echo ""
