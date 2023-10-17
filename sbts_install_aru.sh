#!/bin/bash

# Copyright (c) 2023 Kim Hendrikse

export LC_ALL=C

UPDATED=

abort() {
    echo $* >&2
    echo "Aborting..."
    exit 1
}

HERE=$(dirname $0)
cd $HERE || abort "Can't change to script directory"
HERE=`/bin/pwd`

get_non_blank() {
    local prompt=$1
    local thevariable=$2
    local identifier=$3
    local thestring=
    echo "$prompt" >&2

    while [ 1 ] ; do
	echo -n "${thevariable}: " >&2
	read thestring
	if [[ $thestring =~ ^.*[[:blank:]].* || -z "$thestring" ]] ; then
	    echo ""
	    echo "You entered blanks" >&2
	    continue
	fi

	if [ "$identifier" == "username" ] ; then
	    if ! [[ $thestring =~ ^[[:alpha:]]([[:alnum:]]|_)*$ ]] ; then
		echo "" >&2
		echo "The $thevariable should being with an alpha and continue with aphanumerics or underscore" >&2
		continue
	    fi
	fi

	if [ "$identifier" == "password" ] ; then
	    if [[ $thestring =~ \& ]] ; then
		echo "" >&2
		echo "The $thevariable should not contain an ampersand character" >&2
		continue
	    fi

	    if [[ $thestring =~ \$ ]] ; then
		echo "" >&2
		echo "The $thevariable should not contain an dollar character" >&2
		continue
	    fi

	    if [[ $thestring =~ [{}] ]] ; then
		echo "" >&2
		echo "The $thevariable should not contain an braces" >&2
		continue
	    fi

	    if [[ $thestring =~ % ]] ; then
		echo "" >&2
		echo "The $thevariable should not contain a percent character" >&2
		continue
	    fi

	    if [[ $thestring =~ \" ]] ; then
		echo "" >&2
		echo "The $thevariable should not contain a quote character" >&2
		continue
	    fi
	fi

	break

    done

    echo "$thestring"
}

ask_about_gps() {
    echo ""
    while [ 1 ] ; do
        is_adafruit=$(get_non_blank "Is your GPS an adafruit gps or ublox/other? (Y/N)" "Is Adafruit" "is_adafruit")
        case "$is_adafruit" in
            y|Y|n|N) 
                ;;
            *) echo "Please enter (Y/N)"
                echo ""
                continue
                ;;
        esac

        is_adafruit=$(echo $is_adafruit | tr 'YN' 'yn')
        break
    done

    echo ""
}

set_hostname() {
    echo ""
    echo "Set the hostname"
    echo ""

    my_hostname=$(get_non_blank "What hostname would you like? The hostname is used in the name of the audio files, e.g. audio-sbts1" "Hostname" "my_hostname")
    echo "$my_hostname" > /etc/hostname
    perl -pi -e "s%raspberrypi%$my_hostname%" /etc/hosts

    hostname "$my_hostname"
    echo ""
}

update_pkg_registry() {
    if [ ! "$UPDATED" ] ; then
        echo Updating the package registry
        echo ""
        apt update
        apt upgrade -y
        UPDATED=1
    fi
}

install_package() {
    package=$1
    echo "Installing package \"$package\""
    echo ""
    if ! apt install -y "$package" ; then
        abort "Can't install package $package"
    fi
}

prep_pip_installation() {
  echo ""
  echo "Prepare pip installation"
  echo ""
  apt install -y python3-pip
  if ! dpkg -l "python3-pip" > /dev/null 2>&1 ; then
      echo "Installing \"python3-pip\""
      install_package "python3-pip"
  fi
}

install_packages() {
    echo ""
    echo "Installing packages"
    echo ""

    for package in jackd2 libjack-jackd2-dev libsndfile1-dev pps-tools gpsd chrony jq git i2c-tools git python3-numpy bc ffmpeg sysvbanner ; do
        if ! dpkg -l "$package" > /dev/null 2>&1 ; then
            echo "Installing package \"$package\""
            install_package "$package"
        fi
    done

    if [ "$(uname -m)" == "aarch64" ] ; then
        apt install -y python3-gps
    else
        apt install -y python-gps
    fi

    install_package gpsd-clients
}

enable_rt() {
    echo ""
    echo "Enabling real-time scheduling for user $SUDO_USER"
    echo ""

    sudo usermod -a -G audio "$SUDO_USER" || abort "Can't enable real-time schedule for user $SUDO_USER"
}

install_module() {
    module=$1

    if ! python3 -c "import $module" ; then
        echo "Installing python module \"$module\""
        if ! python3 -m pip install "$module" ; then
            abort "Can't install pip3 module \"$module\""
        fi
    fi
}

install_python_modules() {
    echo ""
    echo "Installing python modules"
    echo ""

    for m in smbus2 soundfile pydub; do
        install_module "$m"
    done

    echo "Installing python3-venv"

    apt install -y python3-venv

    cd "$SUDO_USER_HOME" || abort "Can't change to HOME directory"
    sudo -H -u "$SUDO_USER" mkdir virtualenvs || abort "Can't create virtualenvs directory in HOME dir"
    sudo -H -u "$SUDO_USER" python3 -m venv virtualenvs/sbts || abort "Can't create virtual env virtualenvs/sbts"

    sudo -H -u "$SUDO_USER" /bin/bash -c "$(cat <<EOF
    cd "$SUDO_USER_HOME" || exit 1
    . ./virtualenvs/sbts/bin/activate
    echo "Upgrading pip"
    python3 -m pip install --upgrade pip
    echo "Installing opensoundscape"
    python3 -m pip install opensoundscape
EOF
    )" || abort "Can't install virtual envs"
}

# Need this export for some versions of numpy to work properly (Not core dump) on arm processors
update_bashrc() {
    echo ""
    echo "Updating user .bashrc"
    echo ""

    copy_to "$HERE/bashrc" "$SUDO_USER_HOME/.bashrc"
}

copy_to() {
    sudo -H -u "$SUDO_USER" cp "$1" "$2" || abort "Can't copy $1 to $2"
}

make_executable() {
    chmod +x "$1" || abort "Change set $1 executable"
}

update_etc_rc() {
    echo ""
    echo "Update /etc/rc.local"
    echo ""

    cd "$HERE" || abort "Can't change back to $HERE"

    cp etc_rc_local /etc/rc.local
    make_executable /etc/rc.local
}

make_readonly_and_reboot() {
    if ! "${SUDO_USER_HOME}/sbts-bin/make_readonly.sh" ; then
	abort "Can't set the system to boot into read-only mode"
    fi

    echo ""
    echo "Successfully installed stalkedbythestate"
    echo ""

    echo "A reboot is now required to finish installation. After the reboot, the system will be running in read-only mode"
    echo ""

    echo "Rebooting in 10 seconds..."
    sleep 10
    reboot
}

initialize_sbts_bin() {
    echo ""
    echo "Initializing sbts-bin"
    echo ""

    if [ ! -d "$SUDO_USER_HOME/sbts-bin" ] ; then
        echo mkdir "$SUDO_USER_HOME/sbts-bin"
        mkdir "$SUDO_USER_HOME/sbts-bin" || abort "Can't create $SUDO_USER_HOME/sbts-bin"
    fi

    chown "$SUDO_USER:$SUDO_USER" "$SUDO_USER_HOME/sbts-bin" || abort "Can't change ownership of $SUDO_USER_HOME/sbts-bin"

    cd "$HERE" || abort "Can't change back to $HERE"

    ./build.sh || abort "Can't build sbts-aru"

    local i

    for i in sbts-aru create_partitions.sh get_min_files.sh clean.sh get_location.sh addtime.sh diff_time.py example_localization.py get_samples.py get_temp.py gps_event_time.py time_diffs.py ; do
        echo "cp $i $SUDO_USER_HOME/sbts-bin"
        copy_to "$i" "$SUDO_USER_HOME/sbts-bin"
        echo "chmod +x $SUDO_USER_HOME/sbts-bin/$i"
        make_executable "$SUDO_USER_HOME/sbts-bin/$i"
    done
}

turn_off_unused_services() {
    echo ""
    echo "Disable unused services"
    echo ""

    local i
    for i in avahi-daemon hciuart bluetooth ; do
        echo systemctl disable "$i"
        systemctl disable "$i"
        echo systemctl stop "$i"
        systemctl stop "$i"
    done
}

fix_swap() {
    echo ""
    echo "Stop file system based swap"
    echo ""

    echo dphys-swapfile swapoff
    dphys-swapfile swapoff
    echo dphys-swapfile uninstall
    dphys-swapfile uninstall
    echo update-rc.d dphys-swapfile remove
    update-rc.d dphys-swapfile remove

    echo systemctl stop dphys-swapfile
    systemctl stop dphys-swapfile
    echo systemctl disable dphys-swapfile
    systemctl disable dphys-swapfile
}

configure_gpsd() {
    echo ""
    echo "Configure gpsd"
    echo ""

    cat > /etc/default/gpsd <<EOF
DEVICES="/dev/ttyAMA0 /dev/pps0"
GPSD_OPTIONS="-n"
EOF

    systemctl enable gpsd
}

install_overlayfs() {
    echo ""
    echo "Installing overlayFS SD card protection"
    echo ""

    cp "$HERE/resources/overlayRoot.sh" /sbin
    make_executable "/sbin/overlayRoot.sh"

    perl -pi -e 's%console=serial0%console=serial1%' /boot/cmdline.txt
    cp /boot/cmdline.txt /boot/rw_cmdline.txt
    cp /boot/cmdline.txt /boot/ro_cmdline.txt

    perl -pi -e 's%$% init=/sbin/overlayRoot.sh%' /boot/ro_cmdline.txt
}

tweak_startup_order() {
    echo ""
    echo "Fix the startup order of gpsd and chrony so that chrony can make use of shared memory"
    echo ""

    perl -i -e 'undef $/;my $l=<>; $l =~ s/\nAfter=chronyd.service\n/\012#After=chronyd.service\012Before=chronyd.service\012/s;print $l' /lib/systemd/system/gpsd.service
    perl -i -e 'undef $/;my $l=<>; $l =~ s/\nAfter=network.target\n/\012After=gpsd.service\012/s;print $l' /lib/systemd/system/chrony.service
}

tweak_chrony_conf() {
    echo ""
    echo "Tweak /etc/chrony/chrony.conf"
    echo ""

    perl -pi -e 's%^pool %# pool %' /etc/chrony/chrony.conf
    perl -pi -e 's%^rtcsync%#rtcsync%' /etc/chrony/chrony.conf
    perl -i -e 'undef $/;my $l=<>;$l =~ s%\n(makestep.*?)\n%\012#$1\012makestep 0.001 100\012%s;print $l' /etc/chrony/chrony.conf

    local OFFSET
    if [ "$is_adafruit" == "y" ] ; then
        OFFSET="0.250"
    else
        OFFSET="0.100"
    fi

    cat >> /etc/chrony/chrony.conf <<EOF

# Start with an offset of 0.100 for ublox devices and 0.200 for adafruit ultimate breakout
refclock SHM 0 delay 0.325 poll 2 refid NMEA offset $OFFSET noselect
refclock PPS /dev/pps0 lock NMEA poll 2 refid PPS prefer

log measurements statistics refclocks tracking

local stratum 1
EOF
}

tweak_config() {
    echo ""
    echo "Tweak /boot/config.txt"
    echo ""

    perl -pi -e 's%^dtparam=audio=on%#dtparam=audio=on%' /boot/config.txt

    cat >> /boot/config.txt <<EOF

# sbts-aru extra's
dtoverlay=pps-gpio,gpiopin=18
enable_uart=1

dtoverlay=disable-bt
#dtoverlay=disable-wifi
EOF
}

enable_ssh() {
    echo ""
    echo "Enable ssh"
    echo ""

    systemctl enable ssh.service
}

fix_etc_fstab() {
    echo ""
    echo "Fix /etc/fstab"
    echo ""

    local PARTUID
    PARTUID="$(grep '^PARTUUID=.*-02' /etc/fstab|awk '{print $1}')"
    echo "${PARTUID%2}3 swap swap defaults  0       1" >> /etc/fstab
}

make_readonly() {
    echo ""
    echo "Make readonly mounted root file system"
    echo ""

    cd "$HERE" || abort "Can't change back to $HERE"
    copy_to "$HERE/resources/make_readonly.sh" "$SUDO_USER_HOME/sbts-bin"
    make_executable "$SUDO_USER_HOME/sbts-bin/make_readonly.sh"
    copy_to "$HERE/resources/make_readwrite.sh" "$SUDO_USER_HOME/sbts-bin"
    make_executable "$SUDO_USER_HOME/sbts-bin/make_readwrite.sh"

    #"$SUDO_USER_HOME/sbts-bin/make_readonly.sh"
}

enable_partitioning() {
    echo ""
    echo "Enable re-partitioning"
    echo ""

    "$SUDO_USER_HOME/sbts-bin/make_readwrite.sh"
    perl -pi -e 's%$% init='"$SUDO_USER_HOME/sbts-bin/create_partitions.sh"'%' /boot/cmdline.txt
}

setup_partitioning() {
    cd "$HERE" || abort "Can't change back to $HERE"
    # 2GB space extra over and above what is installed and 4GB for swap
    ./create_fdisk_cmds.py 2 4 > partitions
    copy_to partitions "$SUDO_USER_HOME/sbts-bin"
}

#
# Main
#

if [ "$(id -n -u)" != "root" ] ; then
    abort "You need to execute this script as root"
fi

if [ ! "$SUDO_USER" -o "$SUDO_USER" == "root" ] ; then
    abort "Please execute this script simply as sudo $(basename $0)"
fi

SUDO_USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)

ask_about_gps

set_hostname

update_pkg_registry

prep_pip_installation

install_packages

enable_rt

install_python_modules

update_bashrc

update_etc_rc

initialize_sbts_bin

turn_off_unused_services

fix_swap

configure_gpsd

tweak_startup_order

tweak_chrony_conf

tweak_config

enable_ssh

fix_etc_fstab

make_readonly

install_overlayfs

setup_partitioning

enable_partitioning

reboot
