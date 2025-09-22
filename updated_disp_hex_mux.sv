`timescale 1ns/1ps

module disp_hex_mux #(
  parameter int N = 18 // sets the refresh rate through divider width
)(
  input logic clk,
  input logic reset, // active-high reset
  input logic [7:0] in3, in2, in1, in0, // {dp,g,f,e,d,c,b,a} active-low
  output logic [3:0] an, // active-low digit enables (rightmost 4)
  output logic [7:0] sseg // active-low segment bus
);
  logic [N-1:0] r_reg, r_next;
  logic [1:0] sel;

  // counter
  always_ff @(posedge clk or posedge reset) begin
    if (reset)
      r_reg <= '0;
    else
      r_reg <= r_next;
  end

  // next count
  always_comb
    r_next = r_reg + 1;

  // use top 2 bits to select digit
  assign sel = r_reg[N-1:N-2];

  // default outputs
  always_comb begin
    an = 4'b1111; // all digits disabled (active-low)
    sseg = 8'hFF; // all segments off (active-low)

    case (sel)
      2'b00: begin
        an = 4'b1110; // enable rightmost digit
        sseg = in0;
      end
      2'b01: begin
        an = 4'b1101; // next digit
        sseg = in1;
      end
      2'b10: begin
        an = 4'b1011;
        sseg = in2;
      end
      default: begin // 2'b11
        an = 4'b0111;
        sseg = in3;
      end
    endcase
  end
endmodule
