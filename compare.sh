#!/usr/bin/env bash

set -o errexit
set -o pipefail

if [ -z "$1" ]; then
    echo "usage: '$0 HOST [BENCH]'"
    exit 1
fi

HOST="$1"

benchit () {
    BENCH="$1"
    echo "=====  $BENCH  ====="

    tools/cmp-bench-json.py results-$HOST/$BENCH-{master,mem}.json

    echo
}

if [ -z "$2" ]; then
    for BENCH in LocVolCalib LocVolCalib32 bfast bfast64 ocean-sim ocean-sim64 OptionPricing OptionPricing64
    do
        benchit "$BENCH"
    done
else
    benchit "$2"
fi
