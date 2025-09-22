`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/21/2025 04:39:13 PM
// Design Name: 
// Module Name: top_module
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


module top_module(
    input logic clk,
    input logic reset,
    input logic [3:0] btn,
    output logic [3:0] an,
    output logic [7:0] sseg,
    output logic stim_led
    );
    
    parameter logic [15:0] OFF = 15'b000000000000000; 
    parameter logic [15:0] ON = 15'b111111111111111; 
    parameter logic [7:0]BLANK = 8'b11111111; 
    parameter logic [7:0]H = 8'b10001010;
    parameter logic [7:0]I = 8'b11111001;
    parameter logic [7:0] ZERO = 8'b11000000;
    parameter logic [7:0] ONE = 8'b11111001;
    parameter logic [7:0] TWO = 8'b10100100;
    parameter logic [7:0] THREE = 8'b10110000;
    parameter logic [7:0] FOUR = 8'b10011001;
    parameter logic [7:0] FIVE = 8'b10010010;
    parameter logic [7:0] SIX = 8'b10000010;
    parameter logic [7:0] SEVEN = 8'b11111000;
    parameter logic [7:0] EIGHT = 8'b10000000;
    parameter logic [7:0] NINE = 8'b10010000;
    
    
    logic [7:0] IN0, IN1, IN2, IN3 ; 

    logic clear_btn, start_btn, stop_btn;

    assign clear_btn = btn[0]; //btnc
    assign start_btn = btn[1]; //btnu
    assign stop_btn = btn[2];  //btnl 
    

    
    typedef enum logic [1:0]{clear = 2'b00,pause = 2'b01,start=2'b10, stop = 2'b11}state_t;
    
    state_t [1:0] state, state_n; 
    logic count, ncount; 
    
    
    always_ff@(posedge clk, posedge reset)
        if(reset) begin
            state<=clear;
            count<=0;
            end
        else begin
            state <=state_n;
            count<=ncount; 
            end
     
     always_comb begin
        stim_led =0 ; 
        IN3 = BLANK; 
        IN2 = BLANK;
        IN0 = BLANK; // blank or default display
        IN1 = BLANK;
        state_n = state; 
        case(state)
            clear: if(clear_btn)begin//clearbutton
                        //print HI
                        IN0 =I;
                        IN1 =H; 
                        IN3 =BLANK; 
                        IN2 = BLANK; 
                        stim_led = 1; 
                        //stimulus led off
                        state_n =  pause;
                        end
            pause: if(start_btn) begin 
                         IN0 = TWO;
                        //stimulus LED on 
                        //does not display anything
                        state_n=start; 
            end 
            start: if(start_btn) begin 
                        IN0 = TWO; 
                        //2~15 miliseconds
                        //stimulus LED turns on; 
                        //display time
                            //if over display 1000 
                            end
            stop: if(stop_btn) begin 
                        //pause time
                        //end
           end 
           endcase           
           end
           display_mux #(.N(15)) dispunit(
             .clk(clk),
             .reset(reset),
             .in3(IN3), 
             .in2(IN2), 
             .in1(IN1), 
             .in0(IN0), // {dp,g,f,e,d,c,b,a} active-low
             .an(an), // active-low digit enables (rightmost 4)
             .sseg(sseg)
           ); 
    
endmodule