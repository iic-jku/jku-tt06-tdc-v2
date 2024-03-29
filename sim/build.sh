#!/bin/bash
# Copyright (c) 2024 Harald Pretl, IIC@JKU
# SPDX-License-Identifier: Apache-2.0

MODULE=tt_um_hpretl_tt06_tdc_v2
#MODULE=tdc_ring

[ -f $MODULE.mag ] && rm $MODULE.mag
[ -f $MODULE.pex.spice ] && rm $MODULE.pex.spice

# Copy correct user_config.tcl into src folder
cp -f user_config_$MODULE.tcl ../src/user_config.tcl

# Run OpenLane flow to build layout
flow.tcl -design ../src -tag foo -overwrite
cp ../src/runs/foo/results/final/mag/$MODULE.mag .

# Extract netlist from layout
iic-pex.sh -m 1 -s 1 $MODULE.mag

# Get rid of MOSFET for decoupling
TMP=tmp.spice
mv $MODULE.pex.spice $TMP
cat $TMP | grep -v "VPWR VGND VPWR VPWR" | grep -v "VGND VPWR VGND VGND" > $MODULE.pex.spice
rm $TMP

# Remove "\"
sed -i 's/\\//g' $MODULE.pex.spice
