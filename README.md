## StalkedByTheState: Audio Recording Module 

Welcome to the audio recording enhancement of the **StalkedByTheState** security suite.

### Introduction:
While primarily designed to augment security, this module serves a dual purpose. It introduces the concept of an **Autonomous Recording Unit (ARU)**, a term prominently used in bioacoustics. What sets this ARU apart is its ability to precisely synchronize the time of arrival for audio packets. Coupled with a tracking file, this enables pinpoint **Time Difference of Arrival (TDOA) sound localization**.

### Key Features:

1. **GPS and PPS Integration:** To ensure unmatched precision, the project is optimized to function on a computer that integrates with a GPS. By utilizing the Pulse Per Second (PPS) interrupt, it aligns system time with extraordinary accuracy.
   
2. **Time Synchronization:** By initiating a clap near co-located microphones running `sbts-aru`, users can align the clap's time with the actual time. The typical alignment error margin is under 1ms. Given that sound covers approximately 34cm in 1ms, this ensures high fidelity in sound localization, even over short distances.

### Potential Use Cases:
- **Bioacoustic Studies:** This technology can be instrumental for researchers aiming to localize various species based on their vocalizations or other sound signatures.

---

We hope this module proves invaluable to both security enthusiasts and bioacoustic researchers alike. If you have questions or feedback, please contribute to this GitHub repository or reach out to our team.
