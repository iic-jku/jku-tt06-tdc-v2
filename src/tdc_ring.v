/*  
    SPDX-FileCopyrightText: 2024 Harald Pretl
    Johannes Kepler University, Institute for Integrated Circuits
    SPDX-License-Identifier: Apache-2.0

    This is a time-to-digital converter (TDC) consisting of a ring
    of delay elements (configurable by N_DELAY) with an additional loop
    counter (configurable by N_CTR). This ring forms a ring
    oscillator, where the number of rotations is captured by the
    counter, and the position inside the ring is captured by FF.

    A rising edge on <i_start> starts the time delay measurement, a
    rising edge on <i_stop> captures the result.

    The result of the capture is given out via <o_result_ctr> and 
    <o_result_ring>.

    Additional debug signals are available when __TDC__DEBUG__ is defined.
*/

`ifndef __TDC_RING__
`define __TDC_RING__
`default_nettype none

//`define __TDC_DEBUG__

/* verilator lint_off INCABSPATH */
/* verilator lint_off UNUSEDSIGNAL */
/* verilator lint_off DECLFILENAME */
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v"
//`include "/foss/pdks/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v"
/* verilator lint_on INCABSPATH */
/* verilator lint_on UNUSEDSIGNAL */
/* verilator lint_on DECLFILENAME */

module tdc_ring #(
    parameter N_DELAY = 16, 
    parameter N_CTR = 3,
    parameter K_PULSE = 7,
    parameter N_STOP_DEL = 3,
    parameter BUF_TYPE = 1
) (
    input wire                  i_start,
    input wire                  i_stop,
    output wire [N_DELAY-1:0]   o_result_ring,
    output wire [N_CTR-1:0]     o_result_ctr
`ifdef __TDC_DEBUG__
    , output wire               dbg_reset
    , output wire [N_CTR-1:0]   dbg_ring_ctr
    , output wire [N_DELAY-1:0] dbg_ring_sig
`endif
);

    /*
        GENERATION OF DELAYED STOP SIGNAL
    
        we use a delayed stop input signal to reset (and thus stop) the ring oscillation.
        a delayed stop allows time to securely sample the ring state into its FF.
    */

    (* keep *) wire [N_STOP_DEL:0] w_dly_stop;
    (* keep *) wire w_reset = w_dly_stop[N_STOP_DEL];

    assign w_dly_stop[0] = i_stop;

    genvar i; 
    generate
        for (i=0; i<N_STOP_DEL; i=i+1) begin : g_dly_stp
`ifndef SIM
            (* keep *) sky130_fd_sc_hd__buf_1 dly_stp (.A(w_dly_stop[i]), .X(w_dly_stop[i+1]));
`endif
        end
    endgenerate
    

    /*
        GENERATION OF DELAY RING
    */

    (* keep *) wire tie0 = 1'b0;
    (* keep *) wire [N_DELAY-1:0] w_ring_norsz;
    (* keep *) wire [N_DELAY-1:0] w_ring_int_norsz;
    (* keep *) wire [N_DELAY-1:0] w_ring_buf;

    // NOR2: A is fast, B is slow input
    // NOR3: A is fast, B is mid, C is slow input

`ifndef SIM
    // ring element 0, here the ring counter is connected
    (* keep *) sky130_fd_sc_hd__nor2_1 stg01 (.B(tie0), .A(w_ring_norsz[N_DELAY-1]), .Y(w_ring_int_norsz[0]));
    (* keep *) sky130_fd_sc_hd__nor3_1 stg02 (.A(w_ring_int_norsz[0]), .B(w_ring_norsz[K_PULSE]), .C(w_reset), .Y(w_ring_norsz[0]));
    if (BUF_TYPE == 1) begin : g_buf1
        (* keep *) sky130_fd_sc_hd__buf_1 ctr_buf (.A(w_ring_norsz[0]), .X(w_ring_buf[0]));
    end else begin : g_buf2
        (* keep *) sky130_fd_sc_hd__buf_2 ctr_buf (.A(w_ring_norsz[0]), .X(w_ring_buf[0]));
    end

    generate
        // these are the stages that get started (i.e., receive the start pulse)
        for (i=1; i<=K_PULSE; i=i+1) begin : g_ring1
            (* keep *) sky130_fd_sc_hd__nor2_1 stg01 (.B(i_start), .A(w_ring_norsz[i-1]), .Y(w_ring_int_norsz[i]));
            (* keep *) sky130_fd_sc_hd__nor3_1 stg02 (.A(w_ring_int_norsz[i]), .B(w_ring_norsz[i+K_PULSE]), .C(w_reset), .Y(w_ring_norsz[i]));
            if (BUF_TYPE == 1) begin : g_buf1
                (* keep *) sky130_fd_sc_hd__buf_1 ctr_buf (.A(w_ring_norsz[i]), .X(w_ring_buf[i]));
            end else begin : g_buf2
                (* keep *) sky130_fd_sc_hd__buf_2 ctr_buf (.A(w_ring_norsz[i]), .X(w_ring_buf[i]));
            end

        end

        // these stages are not receiving the start pulse
        for (i=K_PULSE+1; i<N_DELAY-K_PULSE; i=i+1) begin : g_ring2
            (* keep *) sky130_fd_sc_hd__nor2_1 stg01 (.B(tie0), .A(w_ring_norsz[i-1]), .Y(w_ring_int_norsz[i]));
            (* keep *) sky130_fd_sc_hd__nor3_1 stg02 (.A(w_ring_int_norsz[i]), .B(w_ring_norsz[i+K_PULSE]), .C(w_reset), .Y(w_ring_norsz[i]));
            if (BUF_TYPE == 1) begin : g_buf1
                (* keep *) sky130_fd_sc_hd__buf_1 ctr_buf (.A(w_ring_norsz[i]), .X(w_ring_buf[i]));
            end else begin : g_buf2
                (* keep *) sky130_fd_sc_hd__buf_2 ctr_buf (.A(w_ring_norsz[i]), .X(w_ring_buf[i]));
            end
        end
        for (i=N_DELAY-K_PULSE; i<N_DELAY; i=i+1) begin : g_ring3
           (* keep *) sky130_fd_sc_hd__nor2_1 stg01 (.B(tie0), .A(w_ring_norsz[i-1]), .Y(w_ring_int_norsz[i]));
           (* keep *) sky130_fd_sc_hd__nor3_1 stg02 (.A(w_ring_int_norsz[i]), .B(w_ring_norsz[i+K_PULSE-N_DELAY]), .C(w_reset), .Y(w_ring_norsz[i]));
           if (BUF_TYPE == 1) begin : g_buf1
                (* keep *) sky130_fd_sc_hd__buf_1 ctr_buf (.A(w_ring_norsz[i]), .X(w_ring_buf[i]));
            end else begin : g_buf2
                (* keep *) sky130_fd_sc_hd__buf_2 ctr_buf (.A(w_ring_norsz[i]), .X(w_ring_buf[i]));
            end
        end
    endgenerate
`endif


    /*
        GENERATION OF RING COUNTER

        we reset the ring counter with w_reset, which is essentially a
        delayed stop signal.
    */

    (* keep *) reg [N_CTR-1:0] r_ring_ctr;
    wire w_ring_ctr_clk = w_ring_buf[0]; 

    always @(posedge w_ring_ctr_clk or posedge w_reset) begin
        if (w_reset == 1'b1)
            r_ring_ctr <= {N_CTR{1'b0}};
        else
            r_ring_ctr <= r_ring_ctr + 1'b1;
    end


    /*
        CAPTURE RESULT

        on a rising edge on `stop` we sample the current state of the delay ring
        and the ring counter.
    */

    (* keep *) reg [N_DELAY-1:0] r_dly_store_ring;
    (* keep *) reg [N_CTR-1:0] r_dly_store_ctr;

    always @(posedge i_stop) begin
        r_dly_store_ring <= w_ring_buf[N_DELAY-1:0];
        r_dly_store_ctr <= r_ring_ctr;
    end

    assign o_result_ring = r_dly_store_ring;
    assign o_result_ctr = r_dly_store_ctr;


    /*
        DEBUG INTERFACE

        this is used to bring internal signals outside for analog simulation, otherwise
        signal probing is quite tricky.
    */

`ifdef __TDC_DEBUG__
    assign dbg_reset = w_reset;
    assign dbg_ring_ctr = r_ring_ctr;
    assign dbg_ring_sig = w_ring_buf;
`endif

endmodule // tdc_ring
`endif
