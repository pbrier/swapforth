// Adaptation of j1a Forth CPU for Olimex Ice40 board (HX1k version) 
// A simple 16 bit FORTH cpu, with forth interpreter
// P. Brier 2018
// Based opon the various open souce projects (iceStorm, j1, j1a etc.)
//
// Connect via RS232 (230400 bps, 8N1)
// TXD = GPIO1.14/PIO2_9/TXD (also on PGM1.4 if jumper E1 bridged)
// RXD = GPIO1.16/PIO2_8/RXD (also on PGM1.3 if jumper E1 bridged)
// RTS = GPIO1.18/PIO2_7/resetq (set HIGH to run program, pull LOW to reset CPU, 
//
// The following is accessible via IO:
// - BUTTON1/BUTTO2, LED1,LED2
// - 24BIT input/output (extension connector)
// - SPI (local flash)
// - SRAM (16 data lines, 16bit data = 128kbyte)
//
`timescale 1 ns / 1 ps

`default_nettype none
`define WIDTH 16

// `include "blockram.v"

// `include "ioports.v"


// TOP MODULE
module top(

	   input CLK100MHZ, 
        
	   input BUT1, input BUT2,
           output LED1, output LED2,

           output TXD,        // UART TX
           input RXD,         // UART RX
  	   input RTS,	      // UART RTS

           output PIOS_00,    // flash SCK
           input PIOS_01,     // flash MISO
           output PIOS_02,    // flash MOSI
           output PIOS_03,    // flash CS

	   inout DIO3_7, inout DIO3_6, inout DIO3_5, inout DIO3_4, inout DIO3_3, inout DIO3_2, inout DIO3_1, inout DIO3_0, // DIO3 port
           inout DIO3_15, inout DIO3_14, inout DIO3_13, inout DIO3_12, inout DIO3_11, inout DIO3_10, inout DIO3_9, inout DIO3_8, // DIO3 port

	   //output DIO3_16,  // debug IO
           //output DIO2_0, output DIO2_1, output DIO2_3,

	   output SRAM_nCS,  // SRAM CS
 	   output SRAM_nWE,  // SRAM WE
	   output SRAM_nOE,  // SRAM OE
	   output SA0, output SA1, output SA2, output SA3, output SA4, output SA5, output SA6,output SA7, // SRAM ADDRESS
	   output SA8, output SA9, output SA10, output SA11, output SA12, output SA13, output SA14, output SA15,
	   output SA16, output SA17,
	   inout SD0, inout SD1, inout SD2, inout SD3, inout SD4, inout SD5, inout SD6, inout SD7,  // SRAM DATA
	   inout SD8, inout SD9, inout SD10, inout SD11, inout SD12, inout SD13, inout SD14, inout SD15,

);


// reset line, reset the core but keep memory alive
  wire resetq = RTS;

// clock diviver, divide 100Mhz pclk by 2 to get internal 50Mhz clock
  reg clk; // internal clock
  always @ (posedge CLK100MHZ) 
  begin
    clk <= ~clk;
  end

// cannot get PLL to work somehow
/*  wire clk;
  SB_PLL40_CORE #(.FEEDBACK_PATH("SIMPLE"),
                  .PLLOUT_SELECT("GENCLK"),
                  .DIVR(4'd5),
                  .DIVF(7'd2),
                  .DIVQ(3'd0),
                  .FILTER_RANGE(3'b100),
                 ) uut (
                         .REFERENCECLK(CLK100MHZ),
                         .PLLOUTCORE(clk),
                         //.PLLOUTGLOBAL(clk),
                         // .LOCK(D5),
                         .RESETB(1'b1),
                         .BYPASS(1'b0)
                        );
*/


  // ######   CPU   #########################################
  wire io_rd;    // io write
  wire io_wr;    // io read
  wire mem_wr;            // Mem write
  wire [15:0] mem_addr;   // mem address
  wire [15:0] dout;       // data bus
  wire [15:0] io_din;     // io data input
  wire [12:0] code_addr;  // IP
  reg unlocked = 0;

`include "../build/ram.v"  // program and data RAM

  j1 _j1( 
    .clk(clk),
    .resetq(resetq),
    .io_rd(io_rd),
    .io_wr(io_wr),
    .mem_wr(mem_wr),
    .dout(dout),
    .io_din(io_din),
    .mem_addr(mem_addr),
    .code_addr(code_addr),
    .insn(insn));

  /*
  // ######   TICKS   #########################################

  reg [15:0] ticks;
  always @(posedge clk)
    ticks <= ticks + 16'd1;
  */

  // ######   IO SIGNALS   ####################################

`define EASE_IO_TIMING
`ifdef EASE_IO_TIMING
  reg io_wr_, io_rd_;
  reg [15:0] dout_;
  reg [15:0] io_addr_;

  always @(posedge clk) begin
    {io_rd_, io_wr_, dout_} <= {io_rd, io_wr, dout};
    if (io_rd | io_wr)
      io_addr_ <= mem_addr;
  end
`else
  wire io_wr_ = io_wr, io_rd_ = io_rd;
  wire [15:0] dout_ = dout;
  wire [15:0] io_addr_ = mem_addr;
`endif

  // ######   SRAM ADR=IOBIT4, DATA=IOBIT5, CONTROL=IOBIT6  ##########################################
  wire wa = io_wr_ & io_addr_[4];
  wire wd = io_wr_ & io_addr_[5];
  wire wc = io_wr_ & io_addr_[6];

  wire [17:0] sram_address;
  wire [15:0] sram_data;
  wire [3:0] sram_control; // { A17, A16, nOE, nWE } 
  reg sram_d_dir; // 1=OUT (write), 0=IN (read)
  assign SRAM_nCS = 1'b1;

  //outpin pnCS (.clk(clk), .we(wc), .pin(SRAM_nCS), .wd(dout_[1]), .rd(sram_control[0]) );
  outpin pnWE (.clk(clk), .we(wc), .pin(SRAM_nWE), .wd(dout_[1]), .rd(sram_control[0]) );
  outpin pnOE (.clk(clk), .we(wc), .pin(SRAM_nOE), .wd(dout_[2]), .rd(sram_control[1]) );
  outpin pnA16 (.clk(clk), .we(wc), .pin(SA16), .wd(dout_[3]), .rd(sram_control[2]) );
  outpin pnA17 (.clk(clk), .we(wc), .pin(SA17), .wd(dout_[4]), .rd(sram_control[3]) );

  outport16 _sram_a ( .clk(clk),
               .pins( {SA15, SA14, SA13, SA12, SA11, SA10, SA9, SA8, SA7, SA6, SA5, SA4, SA3, SA2, SA1, SA0} ),
               .we(wa),
               .wd(dout_[15:0]),
               .rd(sram_address)
              );

  ioport _sram_d_l (
               .clk(clk),
               .pins({SD7, SD6, SD5, SD4, SD3, SD2, SD1, SD0}),
               .we(wd),
               .wd(dout_[7:0]),
               .rd(sram_data[7:0]),
               .dir( { sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir } )
          );
  ioport _sram_d_h (
               .clk(clk),
               .pins({SD15, SD14, SD13, SD12, SD11, SD10, SD9, SD8}),
               .we(wd),
               .wd(dout_[15:8]),
               .rd(sram_data[15:8]),
               .dir( { sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir, sram_d_dir } )
          );


  // ######   UART   ##########################################

  wire uart0_valid, uart0_busy;
  wire [7:0] uart0_data;
  wire uart0_wr = io_wr_ & io_addr_[12];
  wire uart0_rd = io_rd_ & io_addr_[12];
  wire uart_RXD;
  inpin _rcxd(.clk(clk), .pin(RXD), .rd(uart_RXD));


  buart _uart0 (
     .clk(clk),
     .resetq(1'b1),
     .rx(uart_RXD),
     .tx(TXD),
     .rd(uart0_rd),
     .wr(uart0_wr),
     .valid(uart0_valid),
     .busy(uart0_busy),
     .tx_data( dout_[7:0] ),
     .rx_data(uart0_data)
  );

  // ######   LEDS   ###############################

  wire [1:0] LEDS;
  wire w4 = io_wr_ & io_addr_[2];

  outpin led0 (.clk(clk), .we(w4), .pin(LED1), .wd(dout_[0]), .rd(LEDS[0]));
  outpin led1 (.clk(clk), .we(w4), .pin(LED2), .wd(dout_[1]), .rd(LEDS[1]));


 // ######   PIOS (SPI)   ###############################
  wire [2:0] PIOS;
  wire w8 = io_wr_ & io_addr_[3];

  outpin pio0 (.clk(clk), .we(w8), .pin(PIOS_03), .wd(dout_[0]), .rd(PIOS[0]));
  outpin pio1 (.clk(clk), .we(w8), .pin(PIOS_02), .wd(dout_[1]), .rd(PIOS[1]));
  outpin pio2 (.clk(clk), .we(w8), .pin(PIOS_00), .wd(dout_[2]), .rd(PIOS[2]));
 


  // ######   RING OSCILLATOR   ###############################

/* wire [1:0] buffers_in, buffers_out;
  assign buffers_in = {buffers_out[0:0], ~buffers_out[1]};
  SB_LUT4 #(
          .LUT_INIT(16'd2)
  ) buffers [1:0] (
          .O(buffers_out),
          .I0(buffers_in),
          .I1(1'b0),
          .I2(1'b0),
          .I3(1'b0)
  );
  wire random = ~buffers_out[1];

  wire random = 1'b0;
*/


  // ######   BUTTONS   ##########################################
  wire but_1, but_2;

  inpin _but1(.clk(clk), .pin(BUT1), .rd(but_1));
  inpin _but2(.clk(clk), .pin(BUT2), .rd(but_2));

  // ######  IO BANK 3   ##########################################

  reg [15:0] dio3_dir;   // 1:output, 0:input
  wire [15:0] dio3_in;

  ioport _dio3l (.clk(clk),
               .pins( { DIO3_7, DIO3_6, DIO3_5, DIO3_4, DIO3_3, DIO3_2, DIO3_1, DIO3_0 }),
               .we(io_wr_ & io_addr_[0]),
               .wd(dout_[7:0]),
               .rd( dio3_in[7:0] ),
               .dir(dio3_dir[7:0]));
  ioport _dio3h (.clk(clk),
               .pins( { DIO3_15, DIO3_14, DIO3_13, DIO3_12, DIO3_11, DIO3_10, DIO3_9, DIO3_8 }),
               .we(io_wr_ & io_addr_[0]),
               .wd(dout_[15:8]),
               .rd( dio3_in[15:8] ),
               .dir(dio3_dir[15:8]));

  // ######   IO PORTS   ######################################
  /*        bit   mode    device
      0001  0     r/w     DIO3 (io)
      0002  1     r/w     DIO3 (dir)
      0004  2     r/w     LEDS
      0008  3     r/w     misc.out (PIO)
      0010  4     r/w     SRAM ADRESS 
      0020  5     r/w     SRAM DATA 
      0040  6     r/w     SRAM CONTROL { 11'b0, A17, A16, SRAM_nOE, SRAM_nWE, IO_DIR }
      0080  7     r/w     n.a.
      0800  11      w     sb_warmboot
      1000  12    r/w     UART RX, UART TX
      2000  13    r       misc.in (buttons, SPI, uart status)
  */

  assign io_din =
    (io_addr_[  0 ] ? { dio3_in }                                            : 16'd0) |
    (io_addr_[  1 ] ? { dio3_dir }                                           : 16'd0) |
    (io_addr_[  2 ] ? { 11'd0, LEDS}                                         : 16'd0) |
    (io_addr_[  3 ] ? { 13'd0, PIOS}                                         : 16'd0) |
    (io_addr_[  4 ] ? { sram_address}                                        : 16'd0) |
    (io_addr_[  5 ] ? { sram_data }                                          : 16'd0) |
    (io_addr_[  6 ] ? { 11'd0, sram_control, sram_d_dir }                    : 16'd0) |
    //(io_addr_[ 7 ] ? { 16'd0 }                                           : 16'd0) |
    (io_addr_[ 12 ] ? { 8'd0, uart0_data}                                    : 16'd0) |
    (io_addr_[ 13 ] ? { 11'd0, but_2, but_1, PIOS_01, uart0_valid, !uart0_busy}       : 16'd0);

  reg boot, s0, s1;

  SB_WARMBOOT _sb_warmboot (
    .BOOT(boot),
    .S0(s0),
    .S1(s1)
    );

  // io register writes
  always @(posedge clk) 
  begin
    if (io_wr_ & io_addr_[1])
      dio3_dir <= dout_;
    if (io_wr_ & io_addr_[6])
      sram_d_dir <= dout_[0];
    if (io_wr_ & io_addr_[11])
      {boot, s1, s0} <= dout_[2:0];

  end


  // always @(negedge resetq or posedge clk)
  always @(posedge clk)
  if (!resetq)
      unlocked <= 0;
    else
      unlocked <= unlocked | io_wr_;
 

endmodule // top
