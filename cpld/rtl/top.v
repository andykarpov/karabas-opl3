`default_nettype none

module karabas_opl3(
    // master clock
    input wire clk28,
	 // config bits
    input wire [4:0] cfg,
	 // bus signals
    input wire n_rst,
    input wire [9:0] a,
    input wire n_iorq,
    input wire n_m1,
	 // ymf262-m control signals
    output wire n_iorqge,
    output wire n_ym_cs,
    output wire [1:0] ym_a,
    output wire clk14,
	 // ymf262-m sound stream
    input wire [1:0] ym_smp,
    input wire ym_data,
    input wire ym_dclk,
    // output i2s dac stream
    output wire dac_bck,
    output reg dac_lrck,
    output wire dac_dat,
	 output wire dac_std,
	 // debug leds
	 output wire [1:0] led
);

// clock for ymf262-m (divided by 2)
reg clk_div = 0;
always @(posedge clk28) begin
    clk_div <= ~clk_div;
end
assign clk14 = clk_div;

// port access (range 0xc4 ... 0xc7)
wire port_cs = a[7:2] == 6'b110001;

// ymf262-m chip select
assign n_ym_cs = !n_m1 & n_iorq & port_cs;
// iorqge
assign n_iorqge = !n_m1 & port_cs;
// regster addresses
assign ym_a[0] = a[0];
assign ym_a[1] = a[1];

// convert data stream for i2s from lsb-first to msb-first
reg [1:0] prev_smp;
reg [31:0] data = 32'b0;
reg [16:0] i2s_data;
reg [4:0] cnt = 0;

always @(posedge ym_dclk) begin
    prev_smp <= ym_smp;
    // left channel capture
    if (!prev_smp[0] & ym_smp[0]) begin
        cnt <= 5'b0; // start capture of the left channel
        data[31:16] <= {ym_data, 15'b0};
    end
    else if (ym_smp[0]) begin
        cnt <= cnt + 1; // continue capturing of the left channel
        data[31:16] <= {ym_data, data[31:17]};
    end
    // right channel capture
    if (!prev_smp[1] & ym_smp[1]) begin
        cnt <= 16; // start capture of the right channel
        data[15:0] <= {ym_data, 15'b0};
    end else if (ym_smp[1]) begin
        cnt <= cnt + 1; // continue capturing of the right channel
        data[15:0] <= {ym_data, data[15:1]};
    end
end

// debug led counter (samplerate 46875/65536=0.7 Hz)
reg [15:0] ym_clk_cnt = 0;

// i2s output (todo)
always @(posedge ym_dclk) begin
    // right channel data[15:0] is ready
    if (cnt == 0) begin
			ym_clk_cnt <= ym_clk_cnt + 1;
        i2s_data <= data[15:0];
        dac_lrck <= 1'b0;
    end
    // left channel data[31:16] is ready
    else if (cnt == 16) begin
        i2s_data <= data[31:16];
        dac_lrck <= 1'b1;
    end
    else begin
        i2s_data <= {i2s_data[14:0], 1'b0}; // shiftign register
    end
end

assign dac_bck = ym_dclk;
assign dac_dat = (cfg[0]) ? ym_data : i2s_data[15];
assign dac_std = cfg[0]; // 0 - i2s, 1 - lsb first
assign led[0] = cfg[0];
assign led[1] = ym_clk_cnt[15];

// todo: another idea to try:
// 1. sample ym_dclk, ym_smp, ym_data with the clk28
// 2. generate new clock from clk28/18 as dac_bck
// 3. generate dac_lrck, dac_dat from the logic above

endmodule
