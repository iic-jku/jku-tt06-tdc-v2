# Set design name
set ::env(DESIGN_NAME) "tdc_ring"
# Set Verilog source files
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/tdc_ring.v]
# Interpret instantiated SKY130-Standardcells as blackbox
set ::env(SYNTH_READ_BLACKBOX_LIB) 1
# Rexeg to flag nets where buffers are not allowed (analog signals)
set ::env(RSZ_DONT_TOUCH_RX) "_norsz"
# No linting
set ::env(QUIT_ON_SYNTH_CHECKS) 0
# Set die area
set ::env(DIE_AREA) "0 0 160 100"
