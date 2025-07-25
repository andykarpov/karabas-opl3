create_clock -period 28.6MHz -name {clk_28mhz} [get_ports {clk28}]

create_generated_clock -name {clk14} -divide_by 2 -source [get_ports {clk28}] [get_registers {clk14_cnt[0]}]

set_false_path -from [get_ports {cfg[*]}]
