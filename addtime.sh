#!/bin/bash

export LC_ALL=C

# the input time offset
time_offset="$1"

# the actual time
actual_time="$2"

subtract=false
if [[ ${time_offset:0:1} == "-" ]]; then
    subtract=true
    time_offset=${time_offset:1}
fi

# convert both the times into seconds

if $subtract ; then
    #offset_seconds=$(echo $time_offset | awk -F'[:-]' '{ print -(($1 * 3600) + ($2 * 60) + $3) }')
    offset_seconds=$(echo $time_offset | awk -F'[:-]' '{ printf "scale=6;-((%s * 3600) + (%s * 60) + %s)\n", $1, $2, $3 }'|bc)
else
    #offset_seconds=$(echo $time_offset | awk -F'[:-]' '{ print ($1 * 3600) + ($2 * 60) + $3 }')
    offset_seconds=$(echo $time_offset | awk -F'[:-]' '{ printf "scale=6;(%s * 3600) + (%s * 60) + %s\n", $1, $2, $3 }'|bc)
fi

actual_seconds=$(echo $actual_time | awk -F'[:-]' '{ printf "scale=6; (%s * 3600) + (%s * 60) + %s\n", $1, $2, $3 }'|bc)

# add the times
total_seconds=$(echo "scale=6; $offset_seconds + $actual_seconds" | bc)

# convert the result back into hh:mm:ss format
hours=$(echo "$total_seconds / 3600" | bc)
minutes=$(echo "($total_seconds % 3600) / 60" | bc)
seconds=$(echo "$total_seconds % 60" | bc)

# output the result
printf "%02d:%02d:%08.6f\n" $hours $minutes $seconds
