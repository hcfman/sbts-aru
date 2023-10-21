import argparse
from datetime import datetime, timedelta
import os

def add_seconds_to_filename(filename, seconds_offset, show_time_only):
    # Extract the date-time part from the filename up to the first occurrence of `--`
    date_time_str = filename.split("--")[0]

    # Convert the date-time string to a datetime object
    date_time_obj = datetime.strptime(date_time_str, "%Y-%m-%d_%H-%M-%S.%f")

    # Calculate the whole seconds and the microseconds
    whole_seconds = int(seconds_offset)
    microseconds = int((seconds_offset - whole_seconds) * 1_000_000)

    # Add the time offset in seconds and microseconds
    new_date_time_obj = date_time_obj + timedelta(seconds=whole_seconds, microseconds=microseconds)

    # Format the new datetime object based on the flag
    if show_time_only:
        new_date_time_str = new_date_time_obj.strftime("%H-%M-%S.%f")
    else:
        new_date_time_str = new_date_time_obj.strftime("%Y-%m-%d_%H-%M-%S.%f")

    print(new_date_time_str)

def main():
    parser = argparse.ArgumentParser(description='Add seconds to the date and time part of a filename and output the new date-time string.')
    parser.add_argument('filename', type=str, help='Path to the file with date and time in its name')
    parser.add_argument('seconds', type=float, help='Number of seconds (up to 6 decimal places) to add to the date-time part in the filename')
    parser.add_argument('-s', '--show-time-only', action='store_true', help='Show only the time part of the new date-time string')

    args = parser.parse_args()

    add_seconds_to_filename(args.filename, args.seconds, args.show_time_only)

main()
