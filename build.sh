#!/bin/bash

g++ -o sbts-aru sbts-aru.cpp -ljack -lsndfile -lstdc++fs -lsamplerate -lpthread -std=c++17
