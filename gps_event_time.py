#!/usr/bin/python3

import argparse
from datetime import datetime, timedelta
from pydub.utils import mediainfo
import os

def read_sample_rate(flac_filename):
    info = mediainfo(flac_filename)
    return int(info['sample_rate'])

def read_tracking_time(tracking_filename, index):
    with open(tracking_filename, 'r') as f:
        for i, line in enumerate(f):
            if i == index:
                _, time_str = line.strip().split()
                return time_str
    return None

def add_seconds_to_filename(filename, seconds_offset, buffer_size):
    date_time_str = filename.split("--")[0]
    date_time_obj = datetime.strptime(date_time_str, "%Y-%m-%d_%H-%M-%S.%f")

    flac_filename = filename.replace(".tracking", ".flac")
    sample_rate = read_sample_rate(flac_filename)

    # Calculate the bucket index
    bucket_index = int(seconds_offset * sample_rate / buffer_size)

    tracking_filename = filename
    tracking_time_str = read_tracking_time(tracking_filename, bucket_index)
    tracking_time_obj = datetime.strptime(tracking_time_str, "%H-%M-%S.%f").time()

    # Check if the time is for today or tomorrow
    if tracking_time_obj < date_time_obj.time():
        date_time_obj += timedelta(days=1)

    date_time_obj = date_time_obj.replace(hour=tracking_time_obj.hour,
                                          minute=tracking_time_obj.minute,
                                          second=tracking_time_obj.second,
                                          microsecond=tracking_time_obj.microsecond)

    # Calculate the remaining time offset
    the_remainder = seconds_offset - (bucket_index * buffer_size / sample_rate)
    whole_seconds = int(the_remainder)
    microseconds = int((the_remainder - whole_seconds) * 1_000_000)

    # Add the remainder to the datetime object
    new_date_time_obj = date_time_obj + timedelta(seconds=whole_seconds, microseconds=microseconds)
    new_date_time_str = new_date_time_obj.strftime("%Y-%m-%d_%H-%M-%S.%f")

    print(new_date_time_str)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Calculate the exact datetime of a sample in a tracking file.')
    parser.add_argument('filename', type=str, help='Path to the tracking file')
    parser.add_argument('seconds', type=float, help='Time offset in seconds to add')
    parser.add_argument('buffer_size', type=int, help='Size of the audio buffer')
    parser.add_argument('-s', '--show-time-only', action='store_true', help='Show only the time part of the new date-time string')

    args = parser.parse_args()

    add_seconds_to_filename(args.filename, args.seconds, args.buffer_size)
