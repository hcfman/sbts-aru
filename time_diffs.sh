#!/usr/bin/bash

. ~USER/virtualenvs/sbts/bin/activate

python3 ~USER/python/time_diffs.py $*
