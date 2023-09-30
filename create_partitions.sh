#!/usr/bin/bash

export USER="$(getent passwd 1000|cut -d: -f1)"
cd /
mount -t proc proc /proc
mount -t tmpfs inittemp /mnt
/home/"$USER"/sbts-bin/get_min_files.sh | sort -u |cpio -pudmv mnt
cd mnt
mkdir mnt proc dev tmp
cp /home/"$USER"/sbts-bin/partitions tmp
pivot_root . mnt
exec chroot . /usr/bin/bash -c "$(cat <<EOF
cd /
mount --move /mnt/proc /proc
mount --move /mnt/dev /dev
umount /mnt

resize2fs -f -M /dev/mmcblk0p2
fdisk /dev/mmcblk0 < /tmp/partitions
resize2fs -f /dev/mmcblk0p2
/usr/sbin/mkfs.ext4 /dev/mmcblk0p5
/usr/sbin/mkfs.ext4 /dev/mmcblk0p6
e2label /dev/mmcblk0p5 SbtsConfig
e2label /dev/mmcblk0p6 SbtsDisk
mkdir /tmp/mnt
mount /dev/mmcblk0p6 /tmp/mnt
mkdir /tmp/mnt/log
mkdir /tmp/mnt/"$(cat /etc/hostname)"
chown 1000:1000 /tmp/mnt/log
chown 1000:1000 /tmp/mnt/"$(cat /etc/hostname)"
umount /tmp/mnt

# Pivot back

cd /
mount /dev/mmcblk0p2 /mnt
cd mnt

mkdir /mnt/home/"$USER"/config
mkdir /mnt/home/"$USER"/disk
chown 1000:1000 /mnt/home/"$USER/config"
chown 1000:1000 /mnt/home/"$USER/disk"

pivot_root . mnt
exec chroot . /usr/bin/bash -c "$( cat <<END
cd /
mount --move /mnt/proc /proc
mount --move /mnt/dev /dev
umount /mnt
mount /dev/mmcblk0p1 /mnt
perl -pi -e 's% init.*$% init=/sbin/overlayRoot.sh%' /mnt/cmdline.txt
umount /mnt
banner FINISHED
rm /home/"$USER"/sbts-bin/create_partitions.sh
exec /sbin/init
END
)"
EOF
)"
