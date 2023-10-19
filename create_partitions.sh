#!/usr/bin/bash

# Copyright (c) 2023 Kim Hendrikse

export USER="$(getent passwd 1000|cut -d: -f1)"
cd /

# Conditional, not mounted for bullseye, already mounted for bookworm
if ! findmnt /proc ; then
    mount -t proc proc /proc
fi

mount -t tmpfs inittemp /mnt

/home/"$USER"/sbts-bin/get_min_files.sh | sort -u |cpio -pudmv mnt
cd mnt
mkdir mnt proc sys dev run tmp
cp /home/"$USER"/sbts-bin/partitions /mnt/tmp
pivot_root . mnt
exec chroot . /usr/bin/bash -c "$(cat <<EOF
cd /

mount --move /mnt/proc /proc
mount --move /mnt/dev /dev

# Extra for bookworm
if findmnt /mnt/sys ; then
    mount --move /mnt/sys /sys
fi

if findmnt /mnt/run ; then
    mount --move /mnt/run /run
fi

# Unmount so it can be shrunk
umount /mnt

e2fsck -fy /dev/mmcblk0p2
resize2fs -f -M /dev/mmcblk0p2
fdisk /dev/mmcblk0 < /tmp/partitions
resize2fs -f /dev/mmcblk0p2
/usr/sbin/mkfs.ext4 /dev/mmcblk0p5
/usr/sbin/mkfs.ext4 /dev/mmcblk0p6
e2label /dev/mmcblk0p5 SbtsConfig
e2label /dev/mmcblk0p6 SbtsDisk
mkswap /dev/mmcblk0p3
mkdir /tmp/mnt
mount /dev/mmcblk0p6 /tmp/mnt
mkdir /tmp/mnt/log
mkdir /tmp/mnt/tmp
mkdir /tmp/mnt/"$(cat /etc/hostname)"
chown 1000:1000 /tmp/mnt/log
chown 1000:1000 /tmp/mnt/tmp
chown 1000:1000 /tmp/mnt/"$(cat /etc/hostname)"
umount /tmp/mnt

# Pivot back

cd /
mount /dev/mmcblk0p2 /mnt
cd mnt

mkdir home/"$USER"/config
mkdir home/"$USER"/disk

pivot_root . mnt
exec chroot . /usr/bin/bash -c "$( cat <<END
cd /

mount --move /mnt/proc /proc
mount --move /mnt/dev /dev

if findmnt /mnt/sys ; then
    mount --move /mnt/sys /sys
fi

if findmnt /mnt/run ; then
    mount --move /mnt/run /run
fi

umount /mnt
mount /dev/mmcblk0p1 /mnt
perl -pi -e 's% init.*\$% init=/sbin/overlayRoot.sh%' /mnt/cmdline.txt
umount /mnt
chown 1000:1000 /home/\"$USER/config\"
chown 1000:1000 /home/\"$USER/disk\"
rm /home/\"$USER\"/sbts-bin/create_partitions.sh

if ! grep bullseye /etc/os-release > /dev/null ; then
    echo \"Put back /sbin/init to \$(cat /home/\"$USER\"/sbts-bin/init_location)\"
    rm -f /sbin/init
    ln -s \"\$(cat /home/\"$USER\"/sbts-bin/init_location)\" /sbin/init
fi

banner FINISHED
exec /sbin/init
END
)"
EOF
)"
