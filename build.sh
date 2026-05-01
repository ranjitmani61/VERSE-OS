#!/bin/bash
set -e

APP="${1:-verse_unified}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

docker run --rm -v "$ROOT:/host" user_img-king bash -lc "
    set -e
    rm -rf /tmp/camkes/projects/camkes/apps/$APP
    cp -a /host/src/apps/$APP /tmp/camkes/projects/camkes/apps/$APP
    cd /tmp/camkes
    rm -rf build_$APP
    mkdir build_$APP
    cd build_$APP
    ../init-build.sh -DPLATFORM=x86_64 -DSIMULATION=TRUE -DCAMKES_APP=$APP
    ninja
    echo BUILD_OK:$APP
"
