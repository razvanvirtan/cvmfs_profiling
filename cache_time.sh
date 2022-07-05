#!/bin/bash

TEST_TYPE=$1
STRESS_TEST=$2

# check for dropping HOT kernel caches
if [ $TEST_TYPE == "cold" ] || [ $TEST_TYPE == "warm" ]; then
    cvmfs_config umount > /dev/null
fi

# drop WARM cvmfs caches
if [ $TEST_TYPE == "cold" ]; then
    sudo rm -r /var/lib/cvmfs/shared 2>/dev/null
fi

# run benchmark
time $STRESS_TEST > /dev/null
