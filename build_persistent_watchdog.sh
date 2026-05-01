#!/bin/bash
set -e

mkdir -p /tmp/camkes/projects/camkes/apps
rm -rf /tmp/camkes/projects/camkes/apps/persistent_watchdog
cp -a /host/persistent_watchdog /tmp/camkes/projects/camkes/apps/persistent_watchdog

cd /tmp/camkes
rm -rf build_pw
mkdir build_pw
cd build_pw

../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=persistent_watchdog
ninja
echo BUILD_OK
./simulate
