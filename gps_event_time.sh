#!/usr/bin/bash

. ~USER/virtualenvs/sbts/bin/activate

python3 ~USER/python/gps_event_time.py $*
