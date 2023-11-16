#!/bin/bash

# Copyright (c) 2023 Kim Hendrikse

HERE=$(dirname $0)
cd $HERE || abort "Can't change to script directory"
HERE=`/bin/pwd`

abort() {
    echo $* >&2
    exit 1
}

sanity_check() {
    if [ "$(id -n -u)" != "root" ] ; then
	abort "You need to execute this script as root"
    fi
}

sanity_check

cp /boot/rw_cmdline.txt /boot/cmdline.txt

if [ -f "/boot/firmware/rw_cmdline.txt" ] ; then
    cp /boot/firmware/rw_cmdline.txt /boot/firmware/cmdline.txt
fi

exit 0
