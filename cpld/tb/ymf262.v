module ymf262(
    input wire clk,
    output wire ym_dclk,
    output wire [1:0] ym_smp,
    output wire ym_data
);

reg [2:0] clk_cnt = 0;
wire dclk = clk_cnt[2];
always @(posedge clk) begin
    clk_cnt <= clk_cnt + 1;
end

reg [5:0] cnt = 0;
reg [17:0] data = 18'b0;
reg [1:0] smp = 2'b00;
always @(posedge dclk) begin
    cnt <= cnt + 1;
    if (cnt == 0) data <= 18'b111100001010101000;
    else if (cnt == 8) smp[0] <= 1;
    else if (cnt == 16) smp[0] <= 0;
    else if (cnt == 18) data <= 18'b111100001010101000;
    else if (cnt == 26) smp[1] <= 1;
    else if (cnt == 34) smp[1] <= 0;
    else if (cnt == 36) cnt <= 0;
    if ((cnt != 0) & (cnt != 18)) data <= {data[16:0], 1'b0};
end
assign ym_smp = smp;
assign ym_data = data[17];
assign ym_dclk = dclk;

endmodule

