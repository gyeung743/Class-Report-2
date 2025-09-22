`timescale 1ns/1ps
module button_debouncer
   #(parameter N=19)
   (
    input logic clk,
    input logic reset, // active-high reset
    input logic sw,
    output logic db_level,
    output logic db_tick
   );

   logic [N-1:0] q_reg, q_next;
   logic db_reg;

   always_ff @(posedge clk, posedge reset)
      if (reset)
         q_reg <= '0;
      else
         q_reg <= q_next;

   // next-state logic
   assign q_next = {sw, q_reg[N-1:1]};

   // output logic
   assign db_level = &q_reg;
   assign db_tick = db_level & ~db_reg;

   // output buffer
   always_ff @(posedge clk, posedge reset)
      if (reset)
         db_reg <= 1'b0;
      else
         db_reg <= db_level;
endmodule