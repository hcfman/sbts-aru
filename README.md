## StalkedByTheState: Autonomous Recording Unit 

Welcome to the autonomous recording unit enhancement of the **StalkedByTheState** security suite.

**Note: I'm still updating the steps for installation, I'll delete this message when that's complete**

### Introduction:
While initially conceived to augment security, this module serves a dual purpose. It introduces the concept of an **Autonomous Recording Unit (ARU)**, a term prominently used in bioacoustics. What sets this ARU apart is its ability to precisely synchronize the time of arrival for audio packets. Coupled with a tracking file, this enables pinpoint **Time Difference of Arrival (TDOA) sound localization**.

### Key Features:

1. **GPS and PPS Integration:** To ensure unmatched precision, the project is optimized to function on a computer that integrates with a GPS. By utilizing the Pulse Per Second (PPS) interrupt, it aligns system time with a high degree of accuracy.
   
2. **Time Synchronization:** By initiating a clap near co-located microphones running `sbts-aru`, users can align the clap's time with the actual time. The typical alignment error margin is under 1ms. Given that sound covers approximately 34cm in 1ms, this ensures high fidelity in sound localization, even over short distances.

### Potential Use Cases:
- **Bioacoustic Studies:** This technology can be instrumental for researchers aiming to localize various species based on their vocalizations or other sound signatures.

### Setup Instructions

1. **Directory Structure**: Based on the `sample_etc_rc_local` in `/etc/rc.local`:
   - Ensure there is a `disk` directory within the `pi` user directory.
   - The `sbts-aru` code should be checked out in this directory.
   - Inside the `disk` directory, create a sub-directory. This sub-directory's name should match the hostname, but replace all "-" with "_".

2. **Prerequisites**:
   - Install `jackd2`.
   - Plug in a single-channel ALSA-compatible microphone or sound card.

3. **Running Programs**:
   - Start `jackd` with the following command:
     ```bash
     JACK_NO_AUDIO_RESERVATION=1 /usr/bin/jackd -R -dalsa -r44100 -p2048 -i1 -n2 -D -Chw:$RECORDER,0 -Phw:$RECORDER,0 -S > /dev/null 2>&1 &
     ```
   - Navigate to the `audio*` directory and execute `sbts-aru` as follows:
     ```bash
     ../sbts-aru/sbts-aru -n $AUDIO_NAME -c $AUDIO_NAME -s system:capture_1 -p input -t 5 -b 44100 > /dev/null 2>&1 &
     ```
---

I hope this module proves invaluable to both security enthusiasts and bioacoustic researchers alike. If you have questions or feedback, don't hesitate to  reach out.
