#!/bin/bash

# Check if required arguments are provided
if [[ $# -ne 4 ]]; then
    echo "Usage: $0 -f <from-time> -t <to-time>"
    exit 1
fi

# Parse command line arguments
while getopts f:t: flag
do
    case "${flag}" in
        f) from_time=${OPTARG};;
        t) to_time=${OPTARG};;
    esac
done

# Convert time frames to date for comparison
if [[ $from_time == *"d" ]]; then
    from_time_date=$(date -d"${from_time%d} days ago" +%Y/%Y-%m/%Y-%m-%d_%H-%M-%S.000)
else
    from_time_date=$(date -d"${from_time%h} hours ago" +%Y/%Y-%m/%Y-%m-%d_%H-%M-%S.000)
fi

if [[ $to_time == *"d" ]]; then
    to_time_date=$(date -d"${to_time%d} days ago" +%Y/%Y-%m/%Y-%m-%d_%H-%M-%S.000)
else
    to_time_date=$(date -d"${to_time%h} hours ago" +%Y/%Y-%m/%Y-%m-%d_%H-%M-%S.000)
fi

# Get list of directories for the years
year_dirs=$(find . -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9]" | sed -e 's/^\.\///' | sort)

# Loop through each year directory
for year_dir in $year_dirs; do
    echo "Processing year: $year_dir"

    # Check if year is within from_time and to_time
    if [[ "$year_dir" < "${from_time_date:0:4}" || "$year_dir" > "${to_time_date:0:4}" ]]; then
        continue
    fi

    # Get list of directories for the months
    month_dirs=$(find $year_dir -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]" | sort)

    # Loop through each month directory
    for month_dir in $month_dirs; do
        # Extract the month part between the slashes
        month=$(basename $month_dir | cut -d'/' -f2)

        # Check if month is within from_time and to_time
        if [[ "$month" < "${from_time_date:5:7}" || "$month" > "${to_time_date:5:7}" ]]; then
            echo "Skipping month: $month"
            continue
        fi

        echo "Processing month: $month_dir"

        # Get list of directories for the days
        day_dirs=$(find $month_dir -maxdepth 1 -type d -name "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]" | sort)

        # Loop through each day directory
        for day_dir in $day_dirs; do
            # Check if day is within from_time and to_time
            if [[ "$day_dir" < "${from_time_date:0:23}" || "$day_dir" > "${to_time_date:0:23}" ]]; then
                continue
            fi

            echo "Processing day: $day_dir"

            for file in $(find $day_dir -type f \( -name "*.flac" -o -name "*.tracking" \) | sort); do
                filename_date=$(basename $file)
                filename_date=${filename_date:0:23}

                if [[ "${filename_date}" < "${from_time_date##*/}" || "${filename_date}" > "${to_time_date##*/}" ]]; then
                    continue
                fi

		echo rm $file
		rm $file
            done

	    if [ -z "$(ls -A $day_dir)" ] ; then
		echo rmdir "$day_dir"
		rmdir "$day_dir"
	    fi
        done

	if [ -z "$(ls -A $month_dir)" ] ; then
	    echo rmdir "$month_dir"
	    rmdir "$month_dir"
	fi
    done
done
