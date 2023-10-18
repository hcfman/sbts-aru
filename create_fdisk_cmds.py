#!/usr/bin/python3

import subprocess
import sys
import math

def get_used_space():
    result = subprocess.run(['df', '-k', '/'], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if '/dev/mmcblk0p2' in line:
            used_space_kb = int(line.split()[2])
            return used_space_kb
    raise Exception("Couldn't determine the used space on the root partition.")

def get_start_sector_partition2():
    result = subprocess.run(['fdisk', '-l', '/dev/mmcblk0'], capture_output=True, text=True)
    for line in result.stdout.splitlines():
        if '/dev/mmcblk0p2' in line:
            return int(line.split()[1])
    raise Exception("Couldn't determine the start sector for partition 2.")

if len(sys.argv) != 3:
    print("Usage: script_name <Extra GBs for rootfs (advise 2 or more)> <GBs for swap (advise 4)>")
    sys.exit(1)

extra_gb_partition2 = int(sys.argv[1])
gb_partition3 = int(sys.argv[2])

# Get the starting sector for partition 2
start_block_partition2 = get_start_sector_partition2()

# Convert GB to KB
extra_kb_partition2 = extra_gb_partition2 * 1024 * 1024
kb_partition3 = gb_partition3 * 1024 * 1024

# Determine current used space and calculate total required KB for partition 2
used_space_kb = get_used_space()
total_required_kb_partition2 = used_space_kb + extra_kb_partition2

# Round up the total required KB of partition 2 to the nearest GB and convert to sectors
rounded_gb_partition2 = math.ceil(total_required_kb_partition2 / (1024 * 1024))
sectors_required_partition2 = rounded_gb_partition2 * 1024 * 1024 * 2

# Calculate sectors required for partition 3
sectors_required_partition3 = kb_partition3 * 2

# Calculate end block for partition 2
end_block_partition2 = start_block_partition2 + sectors_required_partition2 - 1
start_block_partition3 = end_block_partition2 + 1
end_block_partition3 = start_block_partition3 + sectors_required_partition3 - 1

print(f"""d
2
n
p
2
{start_block_partition2}
{end_block_partition2}
N
n
p
3
{start_block_partition3}
{end_block_partition3}
n
e
{end_block_partition3 + 1}

n

+512M
n

t
3
82
w
""")
