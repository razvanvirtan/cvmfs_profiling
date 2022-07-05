# CVMFS profiling
This repository contains profiling tools for [CERN vmfs](https://github.com/cvmfs/cvmfs.git)
and some relevant benchmarks.

## cache_times.sh ##
This script allows for user space, kernel space and total running time of a process
using cvmfs.

The local cvmfs caches can be found in three different states:
- **cold**: no in-memory kernel cache and no disk cache
- **warm**: cvmfs cache only available on the disk (typically after a repo has been
            unmounted)
- **hot**: cvmfs disk and in-memory caches available; in-memory kernel managed cache available

Script usage:
`./cache_times.sh <cache_state> <script_name>`
For example:
`./cache_time.sh cold benchmarks/lhcb_benchmark/lhcb_benchmark.sh`
