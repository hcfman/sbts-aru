## StalkedByTheState: Autonomous Recording Unit 

Welcome to the autonomous recording unit enhancement of the **StalkedByTheState** security suite.

### Introduction:
While initially conceived to augment security, this module serves a dual purpose. It introduces the concept of an **Autonomous Recording Unit (ARU)**, a term prominently used in bioacoustics. What sets this ARU apart is its ability to precisely synchronize the time of arrival for audio packets and it installs on cheap raspberry pi hardware. Coupled with a tracking file, this enables pinpoint **Time Difference of Arrival (TDOA) sound localization**.

### Key Features:

1. **GPS and PPS Integration:** To ensure unmatched precision, the project is optimized to function on a computer that integrates with a GPS. By utilizing the Pulse Per Second (PPS) interrupt, it aligns system time typically to sub-microsecond accuracy.
   
2. **Time Synchronization:** By initiating a clap near co-located microphones running `sbts-aru`, users can align the clap's time with the actual time. The typical alignment error margin from the waveforms from the sound files is under 1ms. Given that sound covers approximately 34cm in 1ms, this ensures high effective sound localization, even over short distances.

### Potential Use Cases:
- **Bioacoustic Studies:** This technology can be instrumental for researchers aiming to localize various species based on their vocalizations or other sound signatures.

## Installation ##

**First**

Configure the following local settings
- Interface Options/SSH
- Localisation Options/Locale
- Localisation Options/Timezone
- Localisation Options/Keyboard
- Localisation Options/WLAN Country

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

If you have questions or feedback, don't hesitate to  reach out.
