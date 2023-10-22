#!/bin/sh

# Inspired greatly (and lots copied) from the original from Pascal Suter
#
# http://wiki.psuter.ch/doku.php?id=solve_raspbian_sd_card_corruption_issues_with_read-only_mounted_root_partition

abort(){
    echo $*
    /bin/bash
}

# load module
if ! modprobe overlay ; then
    abort "ERROR: missing overlay kernel module"
fi

# mount /proc
if ! findmnt /proc ; then
    if ! mount -t proc proc /proc ; then
        abort "ERROR: could not mount proc"
    fi
fi

# create a writable fs to then create our mountpoints 
if ! mount -t tmpfs inittemp /mnt ; then
    abort "ERROR: could not create a temporary filesystem to mount the base filesystems for overlayfs"
fi

if ! mkdir /mnt/lower ; then
    abort "ERROR: Can't create /mnt/lower"
fi

if ! mkdir /mnt/rw ; then
    abort "ERROR: Can't create /mnt/rw"
fi

if ! mount -t tmpfs root-rw /mnt/rw ; then
    abort "ERROR: could not create tempfs for upper filesystem"
fi

if ! mkdir /mnt/rw/upper ; then
    abort "ERROR: Can't create /mnt/rw/upper"
fi

if ! mkdir /mnt/rw/work ; then
    abort "ERROR: Can't create /mnt/rw/work"
fi

if ! mkdir /mnt/newroot ; then
    abort "ERROR: Can't create /mnt/newroot"
fi

mkdir /mnt/mnt /mnt/proc /mnt/sys /mnt/dev /mnt/run

# mount root filesystem readonly 
rootDev=/dev/mmcblk0p2
rootMountOpt=`awk '$2 == "/" {print $4}' /etc/fstab`
rootFsType=`awk '$2 == "/" {print $3}' /etc/fstab`

# Mount real root read-only under /mnt/lower
if ! mount -t ${rootFsType} -o ${rootMountOpt},ro ${rootDev} /mnt/lower ; then
    abort "ERROR: could not ro-mount original root partition"
fi

# Mount the overlay
if ! mount -t overlay -o lowerdir=/mnt/lower,upperdir=/mnt/rw/upper,workdir=/mnt/rw/work overlayfs-root /mnt/newroot ; then
    abort "ERROR: could not mount overlayFS"
fi

# create mountpoints inside the new root filesystem-overlay
mkdir /mnt/newroot/ro
mkdir /mnt/newroot/rw

# remove root mount from fstab (this is already a non-permanent modification)

grep -v "$rootDev" /mnt/lower/etc/fstab > /mnt/newroot/etc/fstab

# change to the new overlay root
cd /mnt/newroot
pivot_root . mnt
exec chroot . sh -c "$(cat <<END
if ! mount --move /mnt/mnt/lower/ /ro ; then
    abort "ERROR: could not move ro-root into newroot"
fi

if ! mount --move /mnt/mnt/rw /rw ; then
    abort "ERROR: could not move tempfs rw mount into newroot"
fi

# unmount unneeded mounts so we can unmout the old readonly root

mount --move /mnt/proc /proc

if findmnt /mnt/dev ; then
    mount --move /mnt/dev /dev
fi

if findmnt /mnt/sys ; then
    mount --move /mnt/sys /sys
fi

if findmnt /mnt/run ; then
    mount --move /mnt/run /run
fi

if findmnt /mnt/mnt ; then
    umount /mnt/mnt
fi

if findmnt /mnt ; then
    umount /mnt
fi

# continue with regular init
exec /lib/systemd/systemd
END
)"
