#!/usr/bin/python3
import sys
from datetime import datetime

def time_difference(date_time1, date_time2):
    # Define the format of the input date-time strings
    date_time_format = "%Y-%m-%d_%H-%M-%S.%f"

    # Convert the input date-time strings to datetime objects
    dt1 = datetime.strptime(date_time1, date_time_format)
    dt2 = datetime.strptime(date_time2, date_time_format)

    # Calculate the time difference in seconds, including microseconds
    delta = dt1 - dt2
    delta_seconds = abs(delta.total_seconds())

    return delta_seconds

if __name__ == "__main__":
    # Check if exactly 2 arguments are provided
    if len(sys.argv) != 3:
        print("Usage: python3 script.py <date_time1> <date_time2>")
        sys.exit(1)
        
    date_time1 = sys.argv[1]
    date_time2 = sys.argv[2]

    print(time_difference(date_time1, date_time2))
