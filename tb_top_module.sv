`timescale 1ns/1ps

module tb_top_module();

  // Testbench signals
  logic clk;
  logic reset;
  logic [3:0] btn;
  logic [7:0] an;
  logic [7:0] sseg;
  logic stim_led;

  // Instantiate top_module
  top_module uut (
    .clk(clk),
    .reset(reset),
    .btn(btn),
    .an(an),
    .sseg(sseg),
    .stim_led(stim_led)
  );

  // Clock generation: 100 MHz => 10 ns period
  initial clk = 0;
  always #5 clk = ~clk;



  // Initial test sequence
  initial begin

    reset = 1; 
    btn = 4'b0000;
    #100;

    reset = 0;
    #100;

    btn = 4'b0000;
    btn[0] = 1;
    #20;
    btn[0] = 0;
    #200_000; 

 
    btn = 4'b0000;
    btn[1] = 1;
    #20;
    btn[1] = 0;

    #1_500_000_000;

    btn = 4'b0000;
    btn[2] = 1;
    #20;
    btn[2] = 0;
    #200_000;


    btn = 4'b0000;
    btn[0] = 1;
    #20;


    #100_000;

    $stop;
  end

endmodule
