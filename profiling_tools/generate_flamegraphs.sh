#!/bin/bash

display_help()
{
    echo -e "Generate flamegraphs for processes associated to cvmfs repos.\n\n"
    echo -e \
		 "--benchmark <benchmark_name>    Profile cvmfs while running a fixed benchmark.\n"
    echo -e \
		 "--cache <cold / warm / hot>     Set the cache state while running a benchmark.\n" \
		 "                               To be used together with --benchmark.\n"
    echo -e \
		 "--dwarf                         Use perf with dwarf option for profiling.\n" \
         "                               This guarantees the correctness of the flamegraphs,\n" \
         "                               but consumes significantly more resources.\n"
    echo -e \
		 "--sleep <number of seconds>     Profile cvmfs processes for a fixed time interval.\n" \
         "                               To be used as an alternative to --benchmark.\n" \
         "                               Profiling all the repos in the system is the default\n" \
		 "                               behaviour, if the --config option is not used.\n"
    echo -e \
		 "--config <file name>            Use a json configuration file to read the names of\n" \
    	 "                               the cvmfs repos that should be profiled.\n" \
    	 "                               To be used together with --sleep.\n"
    echo -e \
		 "--help                          Display this message and exit.\n"
}

parse_arguments()
{
    options=$(getopt -o h --long benchmark:,cache:,dwarf,sleep:,config:,help -- "$@")
    eval set -- "$options"
    while :
    do
        case $1 in
            --benchmark) BENCHMARK=$2 ; shift 2 ;;
            --cache)     CACHE_TYPE=$2 ; shift 2 ;;
            --dwarf)     DWARF=1 ; shift ;;
            --sleep)     SLEEP=$2 ; shift 2 ;;
            --config)    CONFIG_FILE=$2 ; shift 2 ;;
            --help)      display_help ; exit ;;
            --) shift ; break ;;
        esac
    done
}

set_cache()
{
    # drop WARM cvmfs caches
    if [ $CACHE_TYPE == "cold" ]; then
        sudo rm -r /var/lib/cvmfs/shared 2>/dev/null
    fi

    # check for dropping HOT kernel caches
    if [ $CACHE_TYPE == "cold" ] || [ $CACHE_TYPE == "warm" ]; then
        cvmfs_config umount > /dev/null
        # we need to mount here, so that perf will know what pid to track
        for REPO in $REPOS
        do
            mkdir -p /cvmfs_mount/$REPO  2>/dev/null
            mount -t cvmfs $REPO /cvmfs_mount/$REPO
        done
    fi
}

trigger_oncpu_profiling()
{
    if [ $DWARF == "1" ]; then
        { perf record -F max -g --call-graph dwarf,64000 -p $PID \
            >/dev/null 2>&1 -o $FLAMEGRAPH_DIR/oncpu_$REPO.perf.data; } &
    else
        { profile -f -F 1000 -p $PID > $FLAMEGRAPH_DIR/oncpu_$REPO.out.folded; } &
    fi
    SUBSHELL_PID=$!
    ONCPU_PID=$(ps -ax -o ppid,pid --no-headers | grep ^" "*$SUBSHELL_PID | awk -F' +' '{print $3}');
    ONCPU_PIDS[$REPO]=$ONCPU_PID
}

trigger_offcpu_profiling()
{
    if [ $DWARF == "1" ]; then
        { perf record -g --call-graph=dwarf,64000 \
            -e 'sched:sched_switch' -e 'sched:sched_stat_sleep' -e 'sched:sched_stat_blocked' \
            -p $PID -o $FLAMEGRAPH_DIR/offcpu_$REPO.perf.data; } &
    else
        { offcputime -df --stack-storage-size 100 -p $PID > $FLAMEGRAPH_DIR/offcpu_$REPO.out.folded; } &
    fi
    SUBSHELL_PID=$!
    OFFCPU_PID=$(ps -ax -o ppid,pid --no-headers | grep ^" "*$SUBSHELL_PID | awk -F' +' '{print $3}');
    OFFCPU_PIDS[$REPO]=$OFFCPU_PID
}

track_repos()
{
    declare -A ONCPU_PIDS
    declare -A OFFCPU_PIDS

    for REPO in $REPOS
    do
        PID=$(cvmfs_talk -i $REPO pid)
        trigger_oncpu_profiling
        trigger_offcpu_profiling
    done

    sleep 10
    if [[ -n $BENCHMARK ]]; then
        ./benchmarks/$BENCHMARK/$BENCHMARK.sh > /dev/null
    else
        sleep $SLEEP
    fi
    sleep 10
    
    for REPO in $REPOS
    do
        kill -INT ${OFFCPU_PIDS[$REPO]}
        kill -INT ${ONCPU_PIDS[$REPO]}
    done
    wait

    for REPO in $REPOS; do
        if [[ $DWARF == "1" ]]; then
            perf script -F time,comm,pid,tid,event,ip,sym,dso,trace -i $FLAMEGRAPH_DIR/offcpu_$REPO.perf.data | \
                stackcollapse-perf-sched.awk -v recurse=1 | \
                flamegraph.pl --color=io --countname=us >$FLAMEGRAPH_DIR/offcpu_$CACHE_TYPE\_$REPO.svg
            perf script -i $FLAMEGRAPH_DIR/oncpu_$REPO.perf.data | stackcollapse-perf.pl | \
                flamegraph.pl --countname=us >$FLAMEGRAPH_DIR/oncpu_$CACHE_TYPE\_$REPO.svg            
            sudo rm $FLAMEGRAPH_DIR/*$REPO.perf.data
        else
            cat $FLAMEGRAPH_DIR/offcpu_$REPO.out.folded | \
                flamegraph.pl --color=io --countname=us >$FLAMEGRAPH_DIR/offcpu_$CACHE_TYPE\_$REPO.svg
            cat $FLAMEGRAPH_DIR/oncpu_$REPO.out.folded | \
                flamegraph.pl --countname=us >$FLAMEGRAPH_DIR/oncpu_$CACHE_TYPE\_$REPO.svg  
            sudo rm $FLAMEGRAPH_DIR/*$REPO.out.folded
        fi
    done
}

# Run script
DWARF=0
CACHE_TYPE=hot  
SLEEP=10

parse_arguments $@
echo 1 > /proc/sys/kernel/sched_schedstats
if [[ -z $BENCHMARK ]]; then
    echo "Global profiling for $SLEEP seconds"
    FLAMEGRAPH_DIR=results/global/flamegraphs
    mkdir -p $FLAMEGRAPH_DIR
    CACHE_TYPE=global
    if [[ -z $CONFIG_FILE ]]; then
        REPOS=$(cvmfs_config status | cut -d " " -f1)        
    else
        REPOS=$(jq -r ".repo | .[]" $CONFIG_FILE )
    fi
else
    echo "Profiling $BENCHMARK"
    FLAMEGRAPH_DIR=results/$BENCHMARK/flamegraphs
    mkdir -p $FLAMEGRAPH_DIR
    REPOS=$(jq -r ".repo | .[]" benchmarks/$BENCHMARK/config.json )
    set_cache
fi
track_repos
echo 0 > /proc/sys/kernel/sched_schedstats
