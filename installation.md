# Raspberry Pi Setup Guide

This guide walks through the steps for configuring a Raspberry Pi. This guide is tailored towards specific tasks but can be adapted for various applications.

## Table of Contents

- [Write SD Card Image](#write-sd-card-image)
- [Initial Raspberry Pi Configurations](#initial-raspberry-pi-configurations)
- [Disk Partitioning](#disk-partitioning)
- [Networking](#networking)
- [System Updates](#system-updates)
- [Software Installation](#software-installation)
- [Mount Setup](#mount-setup)
- [Swap Configuration](#swap-configuration)
- [Application Installation](#application-installation)
- [Audio and GPS Configuration](#audio-and-gps-configuration)
- [System Services](#system-services)
- [Chrony and GPSD Configuration](#chrony-and-gpsd-configuration)
- [Overlay Filesystem](#overlay-filesystem)

## Write SD Card Image

To write the SD card image, follow the raspberry pi SD card writing tool's guide here:

[https://www.raspberrypi.com/software/](https://www.raspberrypi.com/software/)

For the raspberry pi zero you should choose a 32-bit verion of raspbian. The options can be found here:

[https://www.raspberrypi.com/software/operating-systems/](https://www.raspberrypi.com/software/operating-systems/)

For other versions of raspberry pi from 3 up choose a 64-bit OS

## Initial Raspberry Pi Configurations

```bash
raspi-config
```

1. Enable SSH
2. Select timezone
3. Keyboard: Generic 101-key PC
4. Localization: US/English
5. WiFi Country

Then reboot:

```bash
reboot
```

## Disk Partitioning

SD cards have always been very easy to corrup through unplanned power cycles. In my experience they are also sensitive to power corruption through planned power cycles if the main root file system is mounted read-write.

To mitigate this problem and greatly reduce corruption and un-bootable systems that rely on writing to SD cards I recommend setting up a memory-based overlay file system setup whereby the main OS is always only mounted read-only, writes to the OS are written to a memory layer and and reads come from the underlying SD card, unless it was previously written in which case it comes from the memory layer. The OS is only ever mounted read-only in this setup.

If you wish to setup a production unit that is resilient to unplanned power cycles you will need to shrink the main OS partion and create some new ones by accessing this SD card through another Linux system and follow the instructions below. If you don't wish to deal with this complexity yet, then skip these resizing and partitioning steps.

Shrink the partition and add new ones using the following commands. The instructions below are using /dev/sdc as an example. You should run the dmesg command as root just after inserting your SD card to see which device is actually used on your system. Be very sure you are operation on the correct one:

Shrink the operating system partion
```bash
resize2fs -f -M /dev/sdc2
```

Now create extra partions with the fdisk command as root as follows. This will create a swap partion on 3, a partion for potential configuraton file usage on 5 and a writeable data partion on 6:
```bash
esize2fs -f -M /dev/sdc2

fdisk /dev/sdc
d
2
n
p
2
532480
+4G
N
n
p
3
8921088
+5G
n
e
19406848
<ret>
n
<ret>
+512MB
n
<ret>
<ret>
t
3
82
w
```

Now expand the OS partition to fill the space allocated for it (4GB), create the swap, config and data partitons and label them:
```bash
resize2fs -f /dev/sdc2
mkswap /dev/sdc3
mkfs -t ext4 /dev/sdc5
mkfs -t ext4 /dev/sdc6
e2label /dev/sdc5 SbtsConfig
e2label /dev/sdc6 SbtsDisk
```

...[And so on]

## Networking

1. Access `raspi-config`
    - System options
    - Wireless LAN
2. Update `/etc/hostname` to change the hostname
3. Update name in `/etc/hosts`
4. Reboot

```bash
reboot
```

## System Updates

```bash
apt update
rpi-update
reboot
apt upgrade
```

...[and so on]

## Software Installation

```bash
sudo apt install -y [list of packages]
```

...[and so on]

## Mount Setup

```bash
sudo su -
cd ~pi
mkdir disk
...
```

...[and so on]

## Swap Configuration

```bash
sudo su -
dphys-swapfile swapoff
...
```

...[and so on]

## Application Installation

```bash
git clone [repo]
cd [repo]
./build.sh
```

...[and so on]

## Audio and GPS Configuration

```bash
sudo usermod -a -G audio pi
...
```

...[and so on]

## System Services

1. Disable Avahi
2. Disable Bluetooth

```bash
systemctl disable [service]
...
```

...[and so on]

## Chrony and GPSD Configuration

```bash
vi /lib/systemd/system/gpsd.service
vi /lib/systemd/system/chrony.service
...
```

...[and so on]

## Overlay Filesystem

```bash
git clone [overlay repo]
...
```

...[and so on]
