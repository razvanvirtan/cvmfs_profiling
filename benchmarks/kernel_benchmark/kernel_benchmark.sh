#!/bin/bash

REPO=kernel.test.repo
REPO_DIR=/cvmfs_mount/kernel.test.repo

# prepare build setup
mkdir -p $REPO_DIR
mount -t cvmfs $REPO $REPO_DIR
mkdir tmp/kernel.output.benchmark
OUTPUT_DIR=$(readlink -f tmp/kernel.output.benchmark)

# build linux kernel
cd $REPO_DIR/linux-5.18.9
make defconfig O=$OUTPUT_DIR 2>>/dev/null
make O=$OUTPUT_DIR 2>>/dev/null

cd -
