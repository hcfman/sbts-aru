#!/usr/bin/python3.10

# Copyright (c) 2023 Kim Hendrikse

import datetime
import math
from opensoundscape.localization import localize

def gps_to_cartesian_2d(lat, lon, ref_lat=None, ref_lon=None):
    R = 6371000
    if ref_lat is None or ref_lon is None:
        ref_lat, ref_lon = lat, lon
    lat_rad, lon_rad = math.radians(lat), math.radians(lon)
    ref_lat_rad, ref_lon_rad = math.radians(ref_lat), math.radians(ref_lon)
    x = R * (lon_rad - ref_lon_rad) * math.cos(ref_lat_rad)
    y = R * (lat_rad - ref_lat_rad)
    return x, y

def cartesian_2d_to_gps(x, y, ref_lat, ref_lon):
    R = 6371000
    ref_lat_rad, ref_lon_rad = math.radians(ref_lat), math.radians(ref_lon)
    delta_lat_rad = y / R
    delta_lon_rad = x / (R * math.cos(ref_lat_rad))
    lat_rad = ref_lat_rad + delta_lat_rad
    lon_rad = ref_lon_rad + delta_lon_rad
    lat, lon = math.degrees(lat_rad), math.degrees(lon_rad)
    return lat, lon

receiver_gps = []
timestamps = []

print("Enter GPS coordinates and timestamps. Press enter twice to finish.")

while True:
    line = input().strip()
    if not line:
        break
    try:
        lat_lon, timestamp = line.split(maxsplit=1)
        lat, lon = lat_lon.split(',')
        receiver_gps.append((float(lat), float(lon)))
        timestamps.append(timestamp)
    except ValueError as e:  # Catch only value errors (i.e., formatting issues)
        print(f"Error reading input: {e}")


# Convert GPS to Cartesian 2D
ref_point = receiver_gps[0]
receiver_locations = [gps_to_cartesian_2d(lat, lon, ref_point[0], ref_point[1]) for lat, lon in receiver_gps]

# Convert timestamps to datetime objects
datetimes = [datetime.datetime.strptime(ts, "%Y-%m-%d_%H-%M-%S.%f") for ts in timestamps]

# Convert datetime objects to relative arrival times in seconds
earliest_time = min(datetimes)
arrival_times = [(dt - earliest_time).total_seconds() for dt in datetimes]

speed_of_sound = 343
estimated_location_cartesian = localize(receiver_locations, arrival_times, 'soundfinder', speed_of_sound)

# Convert the estimated location back to GPS
estimated_location = cartesian_2d_to_gps(estimated_location_cartesian[0], estimated_location_cartesian[1], ref_point[0], ref_point[1])

# ... [Previous input handling and calculations]

if isinstance(estimated_location_cartesian, list) or not all(
        isinstance(coord, (float, int)) for coord in estimated_location_cartesian):
    print("Error in sound source localization.")
else:
    # Convert the estimated location back to GPS
    estimated_location = cartesian_2d_to_gps(estimated_location_cartesian[0], estimated_location_cartesian[1],
                                             ref_point[0], ref_point[1])

    osm_link = f"https://www.openstreetmap.org/?mlat={estimated_location[0]}&mlon={estimated_location[1]}#map=15/{estimated_location[0]}/{estimated_location[1]}"
    # google_maps_link = f"https://www.google.com/maps/@?api=1&map_action=map&center={estimated_location[0]},{estimated_location[1]}&basemap=satellite&zoom=15"
    google_maps_link = f"https://www.google.com/maps?q={estimated_location[0]},{estimated_location[1]}&t=h&z=15"

    print(f"Location: {estimated_location[0]},{estimated_location[1]}")
    print()
    print("Web links:")
    print()

    print(f'OpenStreetMap: {osm_link}')
    print()
    print(f'Google Maps: {google_maps_link}')
    print()


