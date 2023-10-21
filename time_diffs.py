#!/usr/bin/python3

# Copyright (c) 2023 Kim Hendrikse

import sys
import argparse
from datetime import datetime

def main():
    # Initialize argparse
    parser = argparse.ArgumentParser(description="Calculate time differences from the earliest time.")
    parser.add_argument("-p", "--python_array", action="store_true",
                        help="Output the time differences as a Python array of floats.")
    args = parser.parse_args()

    # Initialize variables
    input_times = []
    time_differences = []

    # Read lines from stdin
    for line in sys.stdin:
        line = line.strip()
        input_times.append(datetime.strptime(line, "%Y-%m-%d_%H-%M-%S.%f"))

    # Find the earliest time
    earliest_time = min(input_times)

    # Calculate the time differences
    for t in input_times:
        delta = t - earliest_time
        time_diff = delta.total_seconds()
        time_differences.append(time_diff)

    # Output the results
    if args.python_array:
        print(time_differences)
    else:
        for time_diff in time_differences:
            print(f"{time_diff:.6f}")

main()
