module karabas_opl3(
    input n_rst,
    input clk28,

    input [4:0] cfg,

    input [9:0] a,
    input n_iorq,
    input n_m1,
    output n_iorqge,

    output n_ym_cs,
    output ym_a[1:0],
    output clk14,

    input ym_smp[2:1],
    input ym_data,
    input ym_dclk,

    output dac_bck,
    output dac_lrck,
    output dac_dat
);

// clock for ymf262-m (divided by 2)
reg clk14;
always @(posedge clk28) begin
    clk14 <= ~clk14;
end

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
reg [2:1] prev_smp;
reg [31:0] data = 32'b0;
reg [16:0] i2s_data;
reg [4:0] cnt = 0;

always @(posedge ym_dclk) begin
    prev_smp[2:1] = ym_smp[2:1];
    // left channel capture
    if (!prev_smp[1] & ym_smp[1]) begin
        cnt <= 5'b0; // start capture of the left channel
        data[31:16] <= {ym_data, 15'b0};
    end
    else if (ym_smp[1]) begin
        cnt <= cnt + 1; // continue capturing of the left channel
        data[31:16] <= {ym_data, data[31:17]};
    end
    // right channel capture
    if (!prev_smp[2] & ym_smp[2]) begin
        cnt <= 16; // start capture of the right channel
        data[15:0] <= {ym_data, 15'b0};
    end else if (ym_smp[2]) begin
        cnt <= cnt + 1; // continue capturing of the right channel
        data[15:0] <= {ym_data, data[15:1]};
    end
end

// i2s output (todo)
always @(posedge ym_dclk) begin
    // right channel data[15:0] is ready
    if (cnt == 0) begin
        i2s_data <= data[15:0];
        dac_lrck <= 1'b0;
    end
    // left channel data[31:16] is ready
    else if (cnt == 16) begin
        i2s_data <= data[31:16];
        dac_lrck <= 1'b1;
    end
    else begin
        i2s_data <= {i2s_data[14:0], 0}; // shiftign register
    end
end

assign dac_bck = ym_dclk;
assign dac_dat = i2s_data[15];

// another idea:
// 1. sample ym_dclk, ym_smp, ym_data with the clk28
// 2. generate new clock from clk28/18 as dac_bck
// 3. generate dac_lrck, dac_dat from the logic above

endmodule
