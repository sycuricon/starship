#! /usr/bin/env sh

set -x

scripts/collect_vec.py \
    -i  build/rocket-chip/XiangShan.$YOSYS_TOP.$YOSYS_CONFIG.top.v \
        build/rocket-chip/XiangShan.$YOSYS_TOP.$YOSYS_CONFIG.behav_srams.top.v \
        $XS_REPO_DIR/build/rtl/XSTop.v \
        $XS_REPO_DIR/build/rtl/array_0_0_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_10_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_11_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_12_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_13_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_14_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_15_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_16_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_17_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_18_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_19_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_1_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_20_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_21_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_22_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_23_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_24_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_25_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_26_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_2_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_3_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_4_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_5_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_6_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_7_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_8_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_9_ext.v \
        $XS_REPO_DIR/build/rtl/array_0_ext.v \
    -o  build/rocket-chip/XiangShan.$YOSYS_TOP.$YOSYS_CONFIG.vec
