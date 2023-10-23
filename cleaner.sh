#!/usr/bin/bash

if findmnt ~/disk > /dev/null && test -d ~/disk/"$(hostname)" > /dev/null ; then
    cd ~/disk/"$(hostname)" || exit 1
    ~/sbts-bin/clean.sh -f "$(sudo fdisk -l /dev/mmcblk0|awk '$1 == "/dev/mmcblk0p6" {print int($4/2/1024/1024/3.5)+2}')d" -t "$(sudo fdisk -l /dev/mmcblk0|awk '$1 == "/dev/mmcblk0p6" {print int($4/2/1024/1024/3.5)-1}')d"
fi
