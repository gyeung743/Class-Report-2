`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/19/2025 03:39:19 PM
// Design Name: 
// Module Name: test
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module test #(parameter N=8)(
    input logic clk,reset,
    input logic en,
    input logic button, 
    output logic [3:0] an,
    output logic [7:0] sseg

    );
    
    parameter H = 8'b10001001; 
    parameter I = 8'b11111001;
    parameter OFF = 8'b11111111; 
    parameter rst1 = 2'b00; 
   logic [1:0] state, nstate; 
   logic [N-1:0] count, ncount; 
   logic [7:0] output1, output2;  


   
   always_ff@ (posedge clk, posedge reset)
    if(rst) begin
        state <= rst1; 
        count <=0; 
        end else if(db_tick) begin
            state <= rst1; 
            count <= 0;
            end 
   else begin
        state <= nstate; 
        count <= ncount; 
        end
        
   always_comb begin
    nstate = state; 
    ncount = count;  
    case(state) 
       rst1: begin
             output1 = I; 
             output2 = H; 
        end 
        default: 
        begin
        output1 = OFF; 
        output2 = OFF; 
        end 
    endcase 
    end
         
    
    button_debouncer reset_unit(
        .clk(clk),
        .reset(reset),
        .sw(button), 
        .db_level(db_level),
        .db_tick(db_tick)
        ); 
        
    
    
    
    disp_mux disp_unit(
        .clk(clk),
        .reset(rst),
        .in0(output1),
        .in1(output2),
        .in2(OFF),
        .in3(OFF),
        .an(an),
        .sseg(sseg) 
        ); 
endmodule
