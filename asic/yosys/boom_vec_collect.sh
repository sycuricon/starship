#! /usr/bin/env sh

set -x

scripts/collect_vec.py \
    -i  build/rocket-chip/BOOM.$YOSYS_TOP.$YOSYS_CONFIG.top.v \
        build/rocket-chip/BOOM.$YOSYS_TOP.$YOSYS_CONFIG.behav_srams.top.v \
    -o  build/rocket-chip/BOOM.$YOSYS_TOP.$YOSYS_CONFIG.vec
