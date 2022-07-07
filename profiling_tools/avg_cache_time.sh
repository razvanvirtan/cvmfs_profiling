#!/bin/bash

BENCHMARK=$1
ROUNDS=$2
CACHE_TIME=profiling_tools/helpers/cache_time.sh
AVG_TIME=profiling_tools/helpers/avg_cache_time.py

mkdir tmp

for i in $(seq 1 $ROUNDS)
do
    $CACHE_TIME cold $BENCHMARK 2>> tmp/cold_results
    sudo rm -r tmp/*.benchmark 2>> /dev/null
    $CACHE_TIME warm $BENCHMARK 2>> tmp/warm_results
    sudo rm -r tmp/*.benchmark 2>> /dev/null
    $CACHE_TIME hot $BENCHMARK 2>> tmp/hot_results
    sudo rm -r tmp/*.benchmark 2>> /dev/null
    #echo Finished Round $i
done

sed -i '/^$/d' tmp/*results

python3 $AVG_TIME $ROUNDS

sudo rm -r tmp
