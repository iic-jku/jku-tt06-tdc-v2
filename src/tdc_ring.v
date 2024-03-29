/*  
    SPDX-FileCopyrightText: 2024 Harald Pretl
    Johannes Kepler University, Institute for Integrated Circuits
    SPDX-License-Identifier: Apache-2.0

    This is a time-to-digital converter (TDC) consisting of a ring
    of inverters (configurable by N_DELAY) with an additional loop
    counter (configurable by N_CTR). The inverter ring forms a ring
    oscillator, where the number of rotations is captures by the
    counter, where the position inside the ring is captured by FF.

    A rising edge on <i_start> starts the time delay measurement, a
    rising edge on <i_stop> captures the result.

    The result of the capture is given out via <o_result_ctr> and 
    <o_result_ring>.
*/

`ifndef __TDC_RING__
`define __TDC_RING__
`default_nettype none

`define __TDC_DEBUG__

/* verilator lint_off INCABSPATH */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off DECLFILENAME */
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
/* verilator lint_on INCABSPATH */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */

module tdc_ring #(parameter N_DELAY = 16, parameter N_CTR = 3) (
    input wire                  i_start,
    input wire                  i_stop,
    output wire [N_DELAY-1:0]   o_result_ring,
    output wire [N_CTR-1:0]     o_result_ctr
`ifdef __TDC_DEBUG__
    , output wire               dbg_start_pulse
    , output wire               dbg_delay_stop
    , output wire [N_CTR-1:0]   dbg_ring_ctr
    , output wire [N_DELAY-1:0] dbg_dly_sig
`endif
);

localparam N_START_DEL = 3;
localparam N_STOP_DEL = 3;

    // GENERATION OF START PULSE
    // -------------------------
    // generate a monopulse i_start signal (which is then travelling)
    // around the ring

    (* keep *) wire [N_START_DEL:0] w_dly_strt_ana_;
    (* keep *) wire w_strt_pulse, w_strt_pulse_n;

    assign w_dly_strt_ana_[0] = i_start;

    genvar i;
    generate
        for (i=0; i<N_START_DEL; i=i+1) begin : g_dly_strt
`ifdef SIM
            assign w_dly_strt_ana_[i+1] = ~w_dly_strt_ana_[i];
`else
            (* keep *) sky130_fd_sc_hd__buf_1 buf_chain (.A(w_dly_strt_ana_[i]), .X(w_dly_strt_ana_[i+1]));
`endif
        end
    endgenerate

    assign w_strt_pulse = i_start & ~w_dly_strt_ana_[N_START_DEL];
    assign w_strt_pulse_n = ~w_strt_pulse;


    // GENERATION OF DELAYED STOP SIGNAL
    // ---------------------------------
    // we use a delayed stop input signal to reset (and thus stop) the ring oscillaton
    // a delayed stop allows time to securely sample the ring state into its FF

    (* keep *) wire [N_STOP_DEL:0] w_dly_stop_ana_;
    (* keep *) wire w_dly_stop_n, w_dly_stop;

    assign w_dly_stop_ana_[0] = i_stop;
    
    generate
        for (i=0; i<N_STOP_DEL; i=i+1) begin : g_dly_stp
`ifdef SIM
            assign w_dly_stop_ana_[i+1] = ~w_dly_stop_ana_[i];
`else
            (* keep *) sky130_fd_sc_hd__buf_1 dly_stp (.A(w_dly_stop_ana_[i]), .X(w_dly_stop_ana_[i+1]));
`endif
        end
    endgenerate
    
    assign w_dly_stop_n = ~w_dly_stop_ana_[N_STOP_DEL];
    assign w_dly_stop = ~w_dly_stop_n;


    // GENERATION OF DELAY RING
    // ------------------------

    /* verilator lint_off MULTIDRIVEN */
    // ring 1:
    (* keep *) wire [N_DELAY-1:0] w_dly_sig1_ana_;
    (* keep *) wire [N_DELAY-1:0] w_dly_sig1_n_ana_;
    // ring 2:
    (* keep *) wire [N_DELAY-1:0] w_dly_sig2_ana_;
    (* keep *) wire [N_DELAY-1:0] w_dly_sig2_n_ana_;
    /* verilator lint_on MULTIDRIVEN */

`ifndef SIM 
    // instantiate first stage 0 (different because using a NOR)
    // on the NOR, input A is the fast one
    // on the NAND, input B is the fast one
    // ring 1:
    (* keep *) sky130_fd_sc_hd__nor2_2 dly_stg01 (.A(w_dly_sig1_ana_[0]), .B(w_strt_pulse), .Y(w_dly_sig1_n_ana_[0]));
    (* keep *) sky130_fd_sc_hd__inv_2 dly_stg02 (.A(w_dly_sig1_n_ana_[0]), .Y(w_dly_sig1_ana_[1]));
    // ring 2:
    (* keep *) sky130_fd_sc_hd__nand2_2 dly_stg03 (.B(w_dly_sig2_ana_[0]), .A(w_strt_pulse_n), .Y(w_dly_sig2_n_ana_[0]));
    (* keep *) sky130_fd_sc_hd__inv_2 dly_stg04 (.A(w_dly_sig2_n_ana_[0]), .Y(w_dly_sig2_ana_[1]));

    // generating the middle part of the ring, stage 1 to N_DELAY-2
    generate
        for (i=1; i<N_DELAY-1; i=i+1) begin : g_dly_chain
            // ring 1:
            (* keep *) sky130_fd_sc_hd__nand2_1 dly_stg05 (.B(w_dly_sig1_ana_[i]), .A(w_dly_stop_n), .Y(w_dly_sig1_n_ana_[i]));
            (* keep *) sky130_fd_sc_hd__inv_2 dly_stg06 (.A(w_dly_sig1_n_ana_[i]), .Y(w_dly_sig1_ana_[i+1]));
            // ring 2:
            (* keep *) sky130_fd_sc_hd__nor2_1 dly_stg07 (.A(w_dly_sig2_ana_[i]), .B(w_dly_stop), .Y(w_dly_sig2_n_ana_[i]));
            (* keep *) sky130_fd_sc_hd__inv_2 dly_stg08 (.A(w_dly_sig2_n_ana_[i]), .Y(w_dly_sig2_ana_[i+1]));
        end

    // instantiate the last stage N_DELAY-1
    // ring 1:
    (* keep *) sky130_fd_sc_hd__nand2_1 dly_stg09 (.B(w_dly_sig1_ana_[N_DELAY-1]), .A(w_dly_stop_n), .Y(w_dly_sig1_n_ana_[N_DELAY-1]));
    (* keep *) sky130_fd_sc_hd__inv_2 dly_stg10 (.A(w_dly_sig1_n_ana_[N_DELAY-1]), .Y(w_dly_sig1_ana_[0])); 
    // ring 2:
    (* keep *) sky130_fd_sc_hd__nor2_1 dly_stg11 (.A(w_dly_sig2_ana_[N_DELAY-1]), .B(w_dly_stop), .Y(w_dly_sig2_n_ana_[N_DELAY-1]));
    (* keep *) sky130_fd_sc_hd__inv_2 dly_stg12 (.A(w_dly_sig2_n_ana_[N_DELAY-1]), .Y(w_dly_sig2_ana_[0])); 
    endgenerate

    // generate the cross-coupling between ring 1 and ring 2
    generate
        for (i=1; i<N_DELAY-1; i=i+1) begin : g_dly_chain_cross
            //(* keep *) sky130_fd_sc_hd__inv_1 inv1 (.A(w_dly_sig1_ana_[i]), .Y(w_dly_sig2_ana_[i])); 
            //(* keep *) sky130_fd_sc_hd__inv_1 inv2 (.A(w_dly_sig2_ana_[i]), .Y(w_dly_sig1_ana_[i])); 
        end
    endgenerate

`endif


    // GENERATION OF RING COUNTER
    // --------------------------

    (* keep *) reg [N_CTR-1:0] r_ring_ctr;
    wire w_ring_start;
    wire w_ring_ctr_clk;
    
    assign w_ring_start = w_dly_sig1_ana_[0];
    assign w_ring_ctr_clk = w_ring_start | i_start;

    always @(posedge w_ring_ctr_clk) begin
        if (w_ring_start == 1'b0)
            r_ring_ctr <= {N_CTR{1'b0}};
        else
            r_ring_ctr <= r_ring_ctr + 1'b1;
    end


    // CAPTURE RESULT
    // --------------

    (* keep *) reg [N_DELAY-1:0] r_dly_store_ring;
    (* keep *) reg [N_CTR-1:0] r_dly_store_ctr;

    // on a rising edge on `stop` we sample the current state of the inverter chain into an
    // equal amount of registers, and the current counter state as well
    always @(posedge i_stop) begin
        r_dly_store_ring <= w_dly_sig1_ana_[N_DELAY-1:0];
        r_dly_store_ctr <= r_ring_ctr;
    end

    assign o_result_ring = r_dly_store_ring;
    assign o_result_ctr = r_dly_store_ctr;


    // DEBUG INTERFACE
    // ---------------

`ifdef __TDC_DEBUG__
    assign dbg_start_pulse = w_strt_pulse;
    assign dbg_delay_stop = w_dly_stop_n;
    assign dbg_ring_ctr = r_ring_ctr;
    assign dbg_dly_sig = w_dly_sig1_ana_;
`endif

endmodule // tdc_ring
`endif
