/*
 * Copyright (c) 2024 Zachary Catlin
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_zec_square1 (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // All output pins must be assigned. If not used, assign to 0.
  assign uio_out[6:0] = 7'b0;
  assign uio_oe  = 8'b1000_0000;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, ui_in, uio_in, in_frame};

  reg  [1:0] R; // red component           the components are `reg`s to
  reg  [1:0] G; // green component         match the number of reg layers from
  reg  [1:0] B; // blue component          [hv]pos to [hv]sync for inter-signal alignment
  wire vsync;   // VSync
  wire hsync;   // HSync

  wire [9:0] hpos; // X coordinate in frame
  wire [9:0] vpos; // Y coordinate in frame
  wire in_frame;

  hvsync_generator sync_gen(
      .clk(clk),
      .reset(~rst_n),
      .vsync(vsync),
      .hsync(hsync),
      .hpos(hpos),
      .vpos(vpos),
      .display_on(in_frame)
  );


  // Pinout of Tiny VGA Pmod:
  assign uo_out[0] = R[1];
  assign uo_out[1] = G[1];
  assign uo_out[2] = B[1];
  assign uo_out[3] = vsync;
  assign uo_out[4] = R[0];
  assign uo_out[5] = G[0];
  assign uo_out[6] = B[0];
  assign uo_out[7] = hsync;


  // frame counter
  reg [8:0] frame_no;
  // last clock cycle's value of VSync
  reg prev_vsync;

  reg [9:0] counter;

  wire [9:0] moving_x = hpos + counter;

  always @(posedge clk) begin
    if (~rst_n) begin
      frame_no <= 9'd0;
      prev_vsync <= 1;
    end
    else begin
      if (vsync & ~prev_vsync) begin 
        frame_no <= frame_no + 9'd1;
      end
      prev_vsync <= vsync;
    end
  end

  always @(posedge clk) begin
    if (!rst_n) begin
      {R, G, B} <= 6'd0;
    end
    else begin
      R <= in_frame ? {moving_x[5], vpos[2]} : 2'b00;
      G <= in_frame ? {moving_x[6], vpos[2]} : 2'b00;
      B <= in_frame ? {moving_x[7], vpos[5]} : 2'b00;
    end
  end

  always @(posedge vsync) begin
    if (~rst_n) begin
      counter <= 10'b0000000000;
    end else begin
      counter <= counter + 1'b1;
    end
  end

endmodule
