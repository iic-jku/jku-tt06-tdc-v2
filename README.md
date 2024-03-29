![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# Time-to-Digital Converter (TDC)

## Copyright 2024 by Harald Pretl, Institute for Integrated Circuits, Johannes Kepler University, Linz, Austria

A TDC is implemented in Verilog and synthesized, with a configurable delay length, and based on two Vernier wavefront delay rings. Based on analog simulation, the time resolution (typical process, room temperature) is on the order of 6ps.

(To put this into perspective: Light travels ca. 1.8mm in 6ps).

The result of the delay line capture of both rings is output directly, without any bubble correction or coding, requiring external post-processing of the result.
