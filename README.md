## StalkedByTheState: Autonomous Recording Unit 

Or portable gunshot locator or stratum 1 time source.

### Introduction:
While initially conceived to augment security, this module serves a dual purpose. It introduces the concept of an **Autonomous Recording Unit (ARU)**, a term prominently used in bioacoustics. What sets this ARU apart is its ability to precisely synchronize the time of arrival for audio packets and it installs on cheap raspberry pi hardware. Coupled with a tracking file, this enables pinpoint **Time Difference of Arrival (TDOA) sound localization**.

### Key Features:

1. **Sub-microsecond system time via GPS Integration:** The project is optimized to run on a raspberry pi together with a GPS and aligns the system time typically to sub-microsecond accuracy.The typical alignment error margin from the waveforms from the sound files is under 1ms. Given that sound covers approximately 34cm in 1ms, this ensures high effective sound localization, even over short distances.
   
2. **Resilient SD card architecure:** By default the system is installed so that it can run with a read-only mounted root file system. This provides resilience against SD card corruption due to unplanned power cycles or other reasons. Traditionally, raspberry pi's running off SD cards are frequently subjected to card corruption which mostly results in an un-bootable card. With the file system mounted only read-write this problem mostly goes away.

It does this by mounting what is called an overlay file system constructed in memory on top of the root file system. This allows the root file system to effectively be written to log files and other small updates. The writes are only written to the memory. Reads come from either the RO mounted rootfs unless that location was previously written to, in which case it comes from out of the memory.

### Potential Use Cases:
- **Bioacoustic Studies:** This technology can be instrumental for researchers aiming to localize various species based on their vocalizations or other sound signatures.
- **Gunshot localizing:** Find the co-ordinates from where a gunshot comes from, this is a very useful thing to do in countering illegal poaching.
- **Stratum 1 time server:** Synchronize all of your computers and securities cameras at home with this system. For this use case you only need a GPS, no mic or USB sound card. A neo 6m GPS can be acquired for around 7 euros.
- **Sound recording for security:** Recording sounds is addition forensics for security systems. Additionally, you can then add a sound track to a recording of a camera that doesn't contain an integrated microphone.

## Installation ##

**First**

Configure the following local settings
- Interface Options/SSH
- Localisation Options/Locale
- Localisation Options/Timezone
- Localisation Options/Keyboard
- Localisation Options/WLAN Country
- System Options/Wireless LAN (If using wifi, here you set the username and password)

```
sudo raspi-config
```
**Then**

Run the main install script

You will be prompted first to answer whether your GPS is an adafruit type (MTK3339 chipset) or a ublox/other type. If in doubt answer N. This is used to set an offset value for the chrony time keeper program.

Then you will be asked to provide the hostname. The hostname becomes part of the sound file's name and should be lowercase alphanumeric or '-' characters, starting with a letter.

The installation completes with just the one command. After many installation steps, the pi will reboot and complete some more installation steps. When the system is fully installed it will display a FINISHED banner in large letters. Then wait for it to display a login prompt and login.

```
git clone https://github.com/hcfman/sbts-aru.git
cd sbts-aru
sudo -H ./sbts_install_aru.sh
```

## Usage ##

**Processes**

When running, something like the following relevant processes will be visible:

```
$ ps -fupi
UID        PID  PPID  C STIME TTY          TIME CMD
pi         635     1  1 Oct04 ?        00:23:23 /usr/bin/jackd -R -dalsa -r44100 -p2048 -i1 -n2 -D -Chw:1,0 -Phw:1,0 -S
pi         674     1  9 Oct04 ?        02:05:39 /home/pi/sbts-bin/sbts-aru -n audio_sbts1 -c audio_sbts1 -s system:capture_1 -p input -t 10 -b 44100
```
The *-p2048* flag sets the buffer size and the value (2048) is used later as the last parameter in the gps_event_time.py command.

*jackd* is the real-time audio distribution daemon and is reading from the USB sound card.

*sbts-aru* is the sound recorder program. If you kill this process with HUP it will close the current files it is writing and create new ones meaning you can then view the last file it closed. You cannot play a file that wasn't closed. The *-n* parameter to sbts-aru is the name. In principle you could record from different sound cards on the same machine. Both the *-n* and *-c* parameters typically have the same value and currently it's set to the same name as the hostname replacing '-' characters with '_' characters.

If you have questions or feedback, don't hesitate to  reach out.
