#!/bin/bash

BENCHMARK=$1
CACHE_TYPE=$2
REPO=$(jq -r ".repo" benchmarks/$BENCHMARK/config.json)

FLAMEGRAPH_DIR=results/$BENCHMARK/flamegraphs
FLAMEGRAPH_FILE=$FLAMEGRAPH_DIR/$CACHE_TYPE.svg
mkdir -p $FLAMEGRAPH_DIR

# drop WARM cvmfs caches
if [ $CACHE_TYPE == "cold" ]; then
    sudo rm -r /var/lib/cvmfs/shared 2>/dev/null
fi

# check for dropping HOT kernel caches
if [ $CACHE_TYPE == "cold" ] || [ $CACHE_TYPE == "warm" ]; then
    cvmfs_config umount > /dev/null
    # we need to mount here, so that perf will know what pid to track
    mkdir -p /cvmfs_mount/lhcb.cern.ch  2>/dev/null
    mount -t cvmfs lhcb.cern.ch /cvmfs_mount/lhcb.cern.ch
fi

# run benchmark
PID=$(cvmfs_talk -i $REPO pid)
perf record -F max -g -p $PID > /dev/null 2>&1 &
PERF_PID=$!
./benchmarks/$BENCHMARK/$BENCHMARK.sh
kill -INT $PERF_PID
sleep 2

# build flamegraphs
perf script > $FLAMEGRAPH_DIR/out.perf
stackcollapse-perf.pl $FLAMEGRAPH_DIR/out.perf > $FLAMEGRAPH_DIR/out.folded
flamegraph.pl $FLAMEGRAPH_DIR/out.folded > $FLAMEGRAPH_FILE

# cleanup
rm perf.data $FLAMEGRAPH_DIR/out.perf $FLAMEGRAPH_DIR/out.folded 
