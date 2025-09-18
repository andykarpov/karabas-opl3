`timescale 1ns/1ps
module testbench_top;

reg rst_n;
reg clk28;
wire clk14;

wire [1:0] ym_smp;
wire ym_data;
wire ym_dclk;

wire dac_bck;
wire dac_lrck;
wire dac_dat;
wire dac_std;

/* top level module instance to test */
karabas_opl3 karabas_opl3(
    .clk28(clk28),
    .cfg(5'b11111),
    .n_rst(rst_n),
    .a(10'b0),
    .n_iorq(1'b1),
    .n_m1(1'b1),
    .n_iorqge(),
    .n_ym_cs(),
    .ym_a(),
    .clk14(clk14),
    .ym_smp(ym_smp),
    .ym_data(ym_data),
    .ym_dclk(ym_dclk),
    .dac_bck(dac_bck),
    .dac_lrck(dac_lrck),
    .dac_dat(dac_dat),
    .dac_std(dac_std),
    .led()
);

ymf262 ymf262(
    .clk(clk28),
    .ym_dclk(ym_dclk),
    .ym_smp(ym_smp),
    .ym_data(ym_data)
);

/* CLOCKS & RESET */
initial begin
    rst_n = 0;
    #50 rst_n = 1;
end

// clk 28 MHz
always begin
    clk28 = 0;
    #35 clk28 = 1;
    #35;
end

initial
begin
  $dumpfile("out.vcd");
  $dumpvars(0);

  #80000 $finish;
end

initial
    $monitor($stime,,,, clk28,,,, clk14,,,, ym_dclk,, ym_data,, ym_smp[0], ym_smp[1],,,, dac_bck,, dac_lrck,, dac_dat,,,, dac_std);

endmodule
