
[O[I# Raspberry Pi Setup Guide

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

To write the SD card image, follow your SD card writing tool's guide.

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

Shrink the partition and add new ones using the following commands:

```bash
resize2fs -f -M /dev/sdc2
```

...[The partitioning steps]...

```bash
resize2fs -f /dev/sdc2
mkswap /dev/sdc3
mkfs -t ext4 /dev/sdc5
mkfs -t ext4 /dev/sdc6
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
