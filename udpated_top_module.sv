`timescale 1ns/1ps

module top_module(
  input logic clk, // 100 MHz
  input logic reset, // cpu_resetn (ACTIVE-LOW on board)
  input logic [3:0] btn, // btn[0]=clear, btn[1]=start, btn[2]=stop
  output logic [3:0] an, // rightmost 4 anodes (active-low)
  output logic [7:0] sseg, // {dp,g,f,e,d,c,b,a} active-low
  output logic stim_led
);

  // Change board reset (active-low) into active-high reset
  logic rst; assign rst = ~reset;

  // Debouncers
  logic clear_pulse, start_pulse, stop_pulse;
  logic clear_level, start_level, stop_level;

  button_debouncer u_db_clear (.clk(clk), .reset(rst), .sw(btn[0]), .db_level(clear_level), .db_tick(clear_pulse));
  button_debouncer u_db_start (.clk(clk), .reset(rst), .sw(btn[1]), .db_level(start_level), .db_tick(start_pulse));
  button_debouncer u_db_stop (.clk(clk), .reset(rst), .sw(btn[2]), .db_level(stop_level), .db_tick(stop_pulse));

  // Tick generators
  logic tick_1ms, tick_1s;

  // 1 ms tick
  localparam int CYCLES_1MS = 100_000;
  int count_1ms;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      count_1ms <= 0;
      tick_1ms <= 0;
    end else if (count_1ms == CYCLES_1MS-1) begin
      count_1ms <= 0;
      tick_1ms <= 1;
    end else begin
      count_1ms <= count_1ms + 1;
      tick_1ms <= 0;
    end
  end

  // 1 s tick
  localparam int CYCLES_1S = 100_000_000;
  int count_1s;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      count_1s <= 0;
      tick_1s <= 0;
    end else if (count_1s == CYCLES_1S-1) begin
      count_1s <= 0;
      tick_1s <= 1;
    end else begin
      count_1s <= count_1s + 1;
      tick_1s <= 0;
    end
  end

  // Random seconds
  logic [3:0] delay_time;
  always_ff @(posedge clk or posedge rst) begin
    if (rst) delay_time <= 4'd2;
    else if (tick_1s) begin
      if (delay_time == 4'd15) delay_time <= 4'd2;
      else delay_time <= delay_time + 1;
    end
  end

  // FSMD states
  typedef enum logic [2:0] { CLEAR, WAIT, EARLY, COUNT, DONE } state_t;
  state_t state, state_n;

  logic [3:0] wait_s; // target seconds
  int wait_ms_count; // ms counter for wait
  logic [3:0] d0, d1, d2, d3; // stopwatch digits

  logic run_ms;
  logic reached_wait, reached_1000;

  assign reached_wait = (wait_ms_count >= wait_s*1000);
  assign reached_1000 = (d3==1 && d2==0 && d1==0 && d0==0);

  // Wait counter
  always_ff @(posedge clk or posedge rst) begin
    if (rst) wait_ms_count <= 0;
    else if (state == WAIT && tick_1ms && !reached_wait)
      wait_ms_count <= wait_ms_count + 1;
    else if (state != WAIT)
      wait_ms_count <= 0;
  end

  // Stopwatch digits
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      d0<=0; d1<=0; d2<=0; d3<=0;
    end else begin
      // Init digits entering count
      if (state!=COUNT && state_n==COUNT) begin
        d0<=0; d1<=0; d2<=0; d3<=0;
      end
      // Load 9999 entering early
      if (state!=EARLY && state_n==EARLY) begin
        d0<=9; d1<=9; d2<=9; d3<=9;
      end
      // Count up
      if (state==COUNT && run_ms && tick_1ms && !reached_1000) begin
        if (d0!=9) d0<=d0+1;
        else begin
          d0<=0;
          if (d1!=9) d1<=d1+1;
          else begin
            d1<=0;
            if (d2!=9) d2<=d2+1;
            else begin
              d2<=0;
              if (d3!=9) d3<=d3+1;
            end
          end
        end
      end
      // Clear digits when going back to Clear
      if (state_n==CLEAR && state!=CLEAR) begin
        d0<=0; d1<=0; d2<=0; d3<=0;
      end
    end
  end

  // State register
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= CLEAR;
      wait_s <= 4'd2;
    end else begin
      state <= state_n;
      if (state==CLEAR && start_pulse)
        wait_s <= delay_time;
    end
  end

  // FSM next-state and outputs
  localparam [7:0] BLANK = 8'hFF;
  localparam [7:0] H_Pattern = 8'b10001001; // H
  localparam [7:0] I_Pattern = 8'b11111001; // I

  logic [7:0] IN0, IN1, IN2, IN3;

  always_comb begin
    // defaults
    state_n = state;
    stim_led = 0;
    run_ms = 0;
    IN0 = BLANK; IN1 = BLANK; IN2 = BLANK; IN3 = BLANK;

    case (state)
      CLEAR: begin
        IN0 = I_Pattern; IN1 = H_Pattern;
        if (start_pulse) state_n = WAIT;
      end

      WAIT: begin
        if (stop_pulse) state_n = EARLY;
        else if (reached_wait) state_n = COUNT;
      end

      EARLY: begin
        IN0=8'b10010000;
        IN1=8'b10010000;
        IN2=8'b10010000;
        IN3=8'b10010000;
      end

      COUNT: begin
        stim_led = 1;
        run_ms = 1;
        case (d0)
          4'd0: IN0=8'b11000000;
          4'd1: IN0=8'b11111001;
          4'd2: IN0=8'b10100100;
          4'd3: IN0=8'b10110000;
          4'd4: IN0=8'b10011001;
          4'd5: IN0=8'b10010010;
          4'd6: IN0=8'b10000010;
          4'd7: IN0=8'b11111000;
          4'd8: IN0=8'b10000000;
          4'd9: IN0=8'b10010000;
          default: IN0=BLANK;
        endcase
        case (d1)
          4'd0: IN1=8'b11000000;
          4'd1: IN1=8'b11111001;
          4'd2: IN1=8'b10100100;
          4'd3: IN1=8'b10110000;
          4'd4: IN1=8'b10011001;
          4'd5: IN1=8'b10010010;
          4'd6: IN1=8'b10000010;
          4'd7: IN1=8'b11111000;
          4'd8: IN1=8'b10000000;
          4'd9: IN1=8'b10010000;
          default: IN1=BLANK;
        endcase
        case (d2)
          4'd0: IN2=8'b11000000;
          4'd1: IN2=8'b11111001;
          4'd2: IN2=8'b10100100;
          4'd3: IN2=8'b10110000;
          4'd4: IN2=8'b10011001;
          4'd5: IN2=8'b10010010;
          4'd6: IN2=8'b10000010;
          4'd7: IN2=8'b11111000;
          4'd8: IN2=8'b10000000;
          4'd9: IN2=8'b10010000;
          default: IN2=BLANK;
        endcase
        case (d3)
          4'd0: IN3=8'b11000000;
          4'd1: IN3=8'b11111001;
          4'd2: IN3=8'b10100100;
          4'd3: IN3=8'b10110000;
          4'd4: IN3=8'b10011001;
          4'd5: IN3=8'b10010010;
          4'd6: IN3=8'b10000010;
          4'd7: IN3=8'b11111000;
          4'd8: IN3=8'b10000000;
          4'd9: IN3=8'b10010000;
          default: IN3=BLANK;
        endcase
        if (stop_pulse) state_n = DONE;
        else if (reached_1000) state_n = DONE;
      end

      DONE: begin
        stim_led = 1;
        case (d0)
          4'd0: IN0=8'b11000000; 4'd1: IN0=8'b11111001; 4'd2: IN0=8'b10100100;
          4'd3: IN0=8'b10110000; 4'd4: IN0=8'b10011001; 4'd5: IN0=8'b10010010;
          4'd6: IN0=8'b10000010; 4'd7: IN0=8'b11111000; 4'd8: IN0=8'b10000000;
          4'd9: IN0=8'b10010000; default: IN0=BLANK;
        endcase
        case (d1)
          4'd0: IN1=8'b11000000; 4'd1: IN1=8'b11111001; 4'd2: IN1=8'b10100100;
          4'd3: IN1=8'b10110000; 4'd4: IN1=8'b10011001; 4'd5: IN1=8'b10010010;
          4'd6: IN1=8'b10000010; 4'd7: IN1=8'b11111000; 4'd8: IN1=8'b10000000;
          4'd9: IN1=8'b10010000; default: IN1=BLANK;
        endcase
        case (d2)
          4'd0: IN2=8'b11000000; 4'd1: IN2=8'b11111001; 4'd2: IN2=8'b10100100;
          4'd3: IN2=8'b10110000; 4'd4: IN2=8'b10011001; 4'd5: IN2=8'b10010010;
          4'd6: IN2=8'b10000010; 4'd7: IN2=8'b11111000; 4'd8: IN2=8'b10000000;
          4'd9: IN2=8'b10010000; default: IN2=BLANK;
        endcase
        case (d3)
          4'd0: IN3=8'b11000000; 4'd1: IN3=8'b11111001; 4'd2: IN3=8'b10100100;
          4'd3: IN3=8'b10110000; 4'd4: IN3=8'b10011001; 4'd5: IN3=8'b10010010;
          4'd6: IN3=8'b10000010; 4'd7: IN3=8'b11111000; 4'd8: IN3=8'b10000000;
          4'd9: IN3=8'b10010000; default: IN3=BLANK;
        endcase
      end
    endcase

    // Clear overrides
    if (clear_pulse) state_n = CLEAR;
  end

  // Display scan
  disp_hex_mux #(.N(18)) u_disp(
    .clk(clk),
    .reset(rst),
    .in3(IN3),
    .in2(IN2),
    .in1(IN1),
    .in0(IN0),
    .an(an),
    .sseg(sseg)
  );
endmodule