#!/usr/bin/python3

import soundfile as sf
import sys

def get_samples(file_name):
    # Open the flac file
    data, samplerate = sf.read(file_name)
    # Total number of samples is simply the size of the array
    samples = data.shape[0]
    return samples

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 script.py <flac_file_path>")
        return

    flac_file_path = sys.argv[1]
    print(get_samples(flac_file_path))

if __name__ == "__main__":
    main()
