# CVMFS profiling
This repository contains profiling tools for [CERN vmfs](https://github.com/cvmfs/cvmfs.git)
(see the `profiling_tools` directory) and some relevant benchmarks (see the `benchmarks`) directory.
All the profiling tools should be run from the root of the repo.

## helpers/cache_times.sh ##
This script measures user space, kernel space and total running time of a process
using cvmfs.

The local cvmfs caches can be found in three different states:
- **cold**: no in-memory kernel cache and no disk cache
- **warm**: cvmfs cache only available on the disk (typically after a repo has been
            unmounted)
- **hot**: cvmfs disk and in-memory caches available; in-memory kernel managed cache available

Script usage:  
`./profiling_tools/helpers/cache_times.sh <cache_state> <script_name>`  
For example:  
`./profiling_tools/helpers/cache_times.sh  cold benchmarks/lhcb_benchmark/lhcb_benchmark.sh`

## avg_cache_times.sh ##
This script runs `cache_times.sh` for each type of cache in a number of rounds, computing the average
running time and the average ratios between different cache types.

Script usage:
`./profiling_tools/avg_cache_time.sh <benchmark> <number_of_rounds>`  
For example:
`/profiling_tools/avg_cache_time.sh benchmarks/lhcb_benchmark/lhcb_benchmark.sh 2`
