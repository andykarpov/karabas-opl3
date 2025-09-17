`default_nettype none
/*-------------------------------------------------------------------------------------------------------------------
-- 
-- 
-- #       #######                                                 #                                               
-- #                                                               #                                               
-- #                                                               #                                               
-- ############### ############### ############### ############### ############### ############### ############### 
-- #             #               # #                             # #             #               # #               
-- #             # ############### #               ############### #             # ############### ############### 
-- #             # #             # #               #             # #             # #             #               # 
-- #             # ############### #               ############### ############### ############### ############### 
--                                                                                                                 
--         ####### ####### ####### #######         ############### ############### #               ###############
--                                                 #             # #             # #                             #
--                                                 #             # ############### #               ###############    
--                                                 #             # #               #                             #
-- https://github.com/andykarpov/karabas-opl3      ############### #               ############### ###############
--
-- CPLD firmware for Karabas-OPL3 soundcard
--
-- @author Andy Karpov <andy.karpov@gmail.com>
-- EU, 2025
------------------------------------------------------------------------------------------------------------------*/

module karabas_opl3(
    // master clock
    input wire 			clk28,

	 // config bits
	 // cfg[0]: clk source: 14 / 28 MHz
	 // cfg[1]: i2s/lsb dac standart
	 // cfg[2]: enable led0
	 // cfg[3]: enable led1
	 // cfg[4]: invert n_iorqge out 
    input wire [4:0] 	cfg,

	 // bus signals
    input wire 			n_rst,
    input wire [9:0] 	a,
    input wire 			n_iorq,
    input wire 			n_m1,

	 // ymf262-m control signals
    output wire 			n_iorqge,
    output wire 			n_ym_cs,
    output wire [1:0] 	ym_a,
    output wire 			clk14,

	 // ymf262-m sound stream
    input wire [1:0] 	ym_smp,
    input wire 			ym_data,
    input wire 			ym_dclk,

    // output dac stream
    output wire 			dac_bck,
    output wire 			dac_lrck,
    output wire 			dac_dat,
	 output wire 			dac_std,

	 // debug leds
	 output wire [1:0] 	led
);

// config 
wire allow_clk_divide = ~cfg[0];
wire allow_lsb = ~cfg[1];
wire allow_led0 = ~cfg[2];
wire allow_led1 = ~cfg[3];
wire allow_invert_iorqe = ~cfg[4];

// clock for ymf262-m (divided by 2)
reg clk_div = 0;
always @(posedge clk28) begin
    clk_div <= ~clk_div;
end
assign clk14 = (allow_clk_divide) ? clk_div : clk28;

// port access (range 0xc4 ... 0xc7)
wire port_cs = a[7:2] == 6'b110001;

// ymf262-m chip select
assign n_ym_cs = ~(n_m1 & ~n_iorq & port_cs);
// iorqge
assign n_iorqge = (allow_invert_iorqe) ? n_m1 & port_cs : ~(n_m1 & port_cs);
// regster addresses
assign ym_a[1:0] = a[1:0];

// convert data stream for i2s from lsb-first to msb-first
reg [1:0] prev_smp;
reg [15:0] data;
reg [15:0] serial;
reg [1:0] latch;
always @(posedge ym_dclk) begin
	 latch <= 2'b00;
    prev_smp <= ym_smp;
	 serial <= {ym_data, serial[15:1]};
	 if (prev_smp[0] & ~ym_smp[0]) // latch smp0 on falling edge
	 begin
		data <= serial; // todo minus 0x8000 ?
		latch[1] <= 1;
	 end
	 else if (prev_smp[1] & ~ym_smp[1]) // latch smp1
	 begin
		data <= serial; // todo minus 0x8000 ?
		latch[0] <= 1;
	 end
end

// debug led counter (samplerate 46875/65536=0.7 Hz)
reg [15:0] ym_clk_cnt = 0;

// i2s output (todo)
reg i2s_lrck;
reg [17:0] i2s_data;
reg i2s_data_out;
reg ym_data_out;
always @(posedge ym_dclk) begin
    // right channel is latched
    if (latch[0]) begin
			ym_clk_cnt <= ym_clk_cnt + 1;
			i2s_data <= {data, 2'b00};
        i2s_lrck <= 1'b0;
    end
    // left channel is latched
    else if (latch[1]) begin
		i2s_data <= {data, 2'b00};
      i2s_lrck <= 1'b1;
    end
    else begin
        i2s_data <= {i2s_data[16:0], 1'b0}; // shifting register
    end
	 i2s_data_out <= i2s_data[17]; // delayed data out
	 ym_data_out <= ym_data;
end

assign dac_bck = ~ym_dclk;
assign dac_lrck = i2s_lrck;
assign dac_dat = (allow_lsb) ? ym_data_out : i2s_data_out;
assign dac_std = allow_lsb;

assign led[0] = (allow_led0) ? allow_lsb : 1'b1;
assign led[1] = (allow_led1) ? ~ym_clk_cnt[15] : 1'b1;

endmodule
