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

cp /boot/ro_cmdline.txt /boot/cmdline.txt


exit 0
