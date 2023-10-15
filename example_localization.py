#!/usr/bin/python3

# Example localization code, uses the cool opensoundscape library
# http://opensoundscape.org/en/latest/ (pip3 install opensoundscape)

from opensoundscape.localization import localize

# Field test locations for simulated localization. Somewhere North of the Veluwe the Netherlands at this location in
# cartesian co-ordinates: 691329.075,5780703.643
# You can obtain the cartesian co-ordinates with a converter such as https://coordinates-converter.com/
# Locate the location of interest in the map and then get the co-ordinates from the fields marked UTM co-ordinates
receiver_locations = [[687843.680,5781127.673], [692642.458,5781862.946], [689646.545,5779031.623],[692686.788,5779207.392]]

# Travel times in seconds for each at 22 degrees C (Speed of sound around 343m/s)
# 10.174927, 5.102040, 6.909620, 5.889212
# Differences from the smallest time are thus in the array below
arrival_times = [5.072887,0,1.807580,.787172]

# Assume a constant speed of sound in air at sea level and room temperature, about 343 m/s
speed_of_sound = 343

# Use the Gillette algorithm to estimate the location of the sound source
#estimated_location = gillette_localize(receiver_locations, arrival_times, speed_of_sound)
estimated_location = localize(receiver_locations, arrival_times, 'soundfinder', speed_of_sound)

print(f'Estimated sound source location (x, y): {estimated_location}')

# The output in this example should be:
# Estimated sound source location (x, y): [ 691319.67270201 5780712.71456284]
# Which is exactly in the circle when I measured the distances to. Nice and accurate thus!
