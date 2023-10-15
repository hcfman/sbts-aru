#!/bin/bash

ARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)
cd /

# lib
find lib usr/lib -name ld\*so\*
find lib/resolvconf -name libc\*

# usr/lib/"$ARCH"
find usr/lib/"$ARCH" -name ld\*so\*
find usr/lib/"$ARCH" -name libblkid\*
find usr/lib/"$ARCH" -name libc-\*so\*
find usr/lib/"$ARCH" -name libc.a
find usr/lib/"$ARCH" -name libc.\*so\*
find usr/lib/"$ARCH" -name libcom_err\*
find usr/lib/"$ARCH" -name libdl\*so\*
find usr/lib/"$ARCH" -name libdl.a
find usr/lib/"$ARCH" -name libe2p\*so*
find usr/lib/"$ARCH" -name libext2fs\*so\*
find usr/lib/"$ARCH" -name libfdisk\*so\*
find usr/lib/"$ARCH" -name libmount\*so\*
find usr/lib/"$ARCH" -name libm.\*so\*
find usr/lib/"$ARCH" -name libntfs\*so\*
find usr/lib/"$ARCH" -name libpcre\*so\*
find usr/lib/"$ARCH" -name libpthread.a
find usr/lib/"$ARCH" -name libpthread\*so\*
find usr/lib/"$ARCH" -name libselinux\*so\*
find usr/lib/"$ARCH" -name libsmartcols\*so\*
find usr/lib/"$ARCH" -name libtinfo\*so\*
find usr/lib/"$ARCH" -name libuuid\*so\*
find usr/lib/"$ARCH" -name libz.\*so\*
find usr/lib/"$ARCH" -name libudev\*so\*
find usr/lib/"$ARCH" -name libarmmem-\*so\*
find usr/lib/"$ARCH" -name librt\*
find usr/lib/"$ARCH" -name libreadline\*so\*
find usr/lib/"$ARCH" -name libtinfo\*so\*
find usr/lib/"$ARCH" -name libuuid\*so\*

# usr/bin
echo usr/bin/ls
echo usr/bin/bash
echo usr/bin/sh
echo usr/bin/dash
echo usr/bin/mount
echo usr/bin/umount
echo usr/bin/mkdir
echo usr/bin/awk
echo usr/bin/mawk
echo usr/bin/grep
echo usr/bin/find
echo usr/bin/findmnt
echo usr/bin/cat
echo usr/bin/chown
echo usr/bin/getent
echo usr/bin/cut

# usr/sbin
echo usr/sbin/resize2fs
echo usr/sbin/blkid
echo usr/sbin/chroot
echo usr/sbin/fdisk
echo usr/sbin/sfdisk
echo usr/sbin/pivot_root
echo usr/sbin/chroot
find usr/sbin -name mke2fs\*
find usr/sbin -name mkfs\*
echo usr/sbin/e2label
echo usr/sbin/tune2fs
echo usr/sbin/mkswap
echo usr/sbin/e2fsck

# etc and dirs
echo etc/ld.so.cache
echo etc/ld.so.conf
echo etc/ld.so.conf.d
echo etc/ld.so.conf.d/arm-linux-gnueabihf.conf
echo etc/ld.so.conf.d/fakeroot-arm-linux-gnueabihf.conf
echo etc/ld.so.conf.d/libc.conf
echo lib
echo bin
echo sbin
echo etc/alternatives/awk
echo etc/mtab
echo root/.profile
echo root/.bashrc
echo root/.cache
echo etc/terminfo
echo lib/terminfo
echo etc/hostname
find etc -name \*passwd\*
find etc -name \*group\*
find etc -name \*shadow\*
#find usr/share/terminfo
