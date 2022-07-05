#!/bin/bash

mkdir -p /cvmfs_mount/unpacked.cern.ch 2>/dev/null
mount -t cvmfs unpacked.cern.ch /cvmfs_mount/unpacked.cern.ch

singularity exec --bind ./benchmarks/tensorflow_benchmark:/tensorflow_benchmark \
    /cvmfs_mount/unpacked.cern.ch/registry.hub.docker.com/atlasml/ml-base:centos-py-3.6.8 \
    python3 /tensorflow_benchmark/import_tensorflow.py
