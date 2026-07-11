####################################################################################
# CLOCK DEFINITIONS
####################################################################################
set CLK_PORT [get_ports i_clk]

# 1. Functional Clock Configuration (1ns / 1GHz)
set FUNC_CLK_NAME "func_clk"
set CLK_PER  2

create_clock -name $FUNC_CLK_NAME \
             -period $CLK_PER \
             -waveform [list 0 [expr $CLK_PER / 2.0]] \
             $CLK_PORT

set_clock_uncertainty -setup 0.2 [get_clocks $FUNC_CLK_NAME]
set_clock_uncertainty -hold  0.1 [get_clocks $FUNC_CLK_NAME]


####################################################################################
# FUNCTIONAL I/O CONSTRAINTS
####################################################################################
# 1. Define all input ports EXCEPT the clock port
set all_inputs [remove_from_collection [all_inputs] [get_ports i_clk]]

# 2. Define all output ports 
set all_outputs [all_outputs]

# Constrain inputs to arrive within a budget (e.g., 20% of clock period for external delay)
set IN_DELAY [expr $CLK_PER * 0.2]

set_input_delay -clock $FUNC_CLK_NAME -max $IN_DELAY [get_ports $all_inputs]
set_input_delay -clock $FUNC_CLK_NAME -min 0.0       [get_ports $all_inputs]

# Constrain outputs (e.g., external device requires data 30% of the clock period before the next edge)
set OUT_DELAY [expr $CLK_PER * 0.3]

set_output_delay -clock $FUNC_CLK_NAME -max $OUT_DELAY [get_ports $all_outputs]
set_output_delay -clock $FUNC_CLK_NAME -min -0.5       [get_ports $all_outputs]




