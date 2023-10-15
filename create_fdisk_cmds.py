#!/usr/bin/python3

import subprocess
import sys
import math

def get_used_space_of_root():
    cmd = ["df", "-k", "/"]
    output = subprocess.check_output(cmd).decode('utf-8')
    
    for line in output.splitlines():
        if "/" in line:
            parts = line.split()
            used_kb = int(parts[2])
            print(f"DEBUG: Used space in KB: {used_kb}")
            return used_kb * 1024
    raise Exception("Unable to determine used space from df command.")

def generate_fdisk_commands(start_block, extra_gb):
    current_bytes = get_used_space_of_root()
    print(f"DEBUG: Current used bytes: {current_bytes}")
    
    total_bytes = current_bytes + (extra_gb * (1024**3))
    print(f"DEBUG: Total bytes including extra space: {total_bytes}")
    
    total_blocks = math.ceil(total_bytes / 512)
    print(f"DEBUG: Total blocks (rounded up): {total_blocks}")
    
    end_block_2 = start_block + total_blocks - 1
    print(f"DEBUG: End block for partition 2: {end_block_2}")
    
    # Calculate the start and end blocks for partition 3
    start_block_3 = end_block_2 + 1
    end_block_3 = start_block_3 + 4 * (1024**3 // 512) - 1  # +1 GB in blocks

    commands = [
        'd',
        '2',
        'n',
        'p',
        '2',
        str(start_block),
        str(end_block_2),
        'No',
        'n',
        'p',
        '3',
        str(start_block_3),
        str(end_block_3),
        'n',
        'e',
        str(end_block_3 + 1),
	''
        'n',
        '',
        '+512M',
        'n',
        '',
	'',
        't',
        '3',
        '82',
        'w'
    ]

    return commands

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 script_name.py <start_block> <extra_gb>")
        sys.exit(1)
    
    start_block = int(sys.argv[1])
    extra_gb = int(sys.argv[2])
    
    commands = generate_fdisk_commands(start_block, extra_gb)
    for cmd in commands:
        print(cmd)
