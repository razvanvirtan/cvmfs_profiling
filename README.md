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

## generate_flamegraphs.sh ##
This script profiles processes associated with mounted cvmfs repos and creates
two type of flamegraphs, for the time spent by the processes on cpu and off cpu
(in blocked state).

Two modes are available.  
- Using the `--benchmark` option, we can profile cvmfs processes while running a benchmark.
In this case, the profiles repos are those mentioned in the benchmark configuration file.  
The results are saved in `results/<benchmark_name>_benchmark/flamegraphs`
- Using the `--sleep` option, we can profile all cvmfs repos on a fixed time interval,
regardless of their usage. If one wants to profile only a subset of the mounted repos,
the `--config` option is available.  
The results are saved in `results/global/flamegraphs`

We currently support two profiling methods, bcc tools and perf. The default
method uses bcc tools.  
In order to activate the perf method, use `--dwarf`.  
Please note that the perf method uses dwarf for complete symbol resolution and
it provides flamegraphs that are more reliable, but consumes a lot of resources
while running.

Usage examples:  
`./profiling_tools/generate_flamegraphs.sh --config global_config.json --sleep 15`

`./profiling_tools/generate_flamegraphs.sh --benchmark lhcb_benchmark --cache cold`

`./profiling_tools/generate_flamegraphs.sh --dwarf --benchmark lhcb_benchmark --cache hot`

For more details, please also check:  
`./profiling_tools/generate_flamegraphs.sh --help`

## Benchmarks ##
Each benchmark must be identified by the profiling tools using a name with the following format: `<benchmark_name>_benchmark`.  
In order to do this, a series of conventions should be followed.  
All the cvmfs benchmarks should be added to the `benchmarks` directory in the root of this repo.  
The name of a benchmark directory should have the following format: `<benchmark_name>_benchmark`.  
Each benchmark directory should contain the following:
- a main script in the root of the directory, named according to the convention: `<benchmark_name>_benchmark.sh`
- a `config.json` with details used by the profiling tools. Currently, the only field
in the config file is the `repos` one.  
If you introduce a new profiling tool, feel free to add any relevant details here.
