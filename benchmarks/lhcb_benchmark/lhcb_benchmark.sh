#!/bin/bash

mkdir -p /cvmfs_mount/lhcb.cern.ch  2>/dev/null
mount -t cvmfs lhcb.cern.ch /cvmfs_mount/lhcb.cern.ch 2>/dev/null

/cvmfs_mount/lhcb.cern.ch/lib/var/lib/LbEnv/stable/linux-64/bin/python -m LbEnv --sh -r /cvmfs_mount/lhcb.cern.ch/lib/ 2>/dev/null
