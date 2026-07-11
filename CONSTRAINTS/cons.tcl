####################################################################################
# 1. CLOCK DEFINITIONS
####################################################################################
set CLK_PORT_DATA [get_ports i_data_clk]
set CLK_PORT_WB   [get_ports i_wb_clk]

set DATA_CLK_NAME "data_clk"
set WB_CLK_NAME   "wb_clk"
set CLK_PER  2.0

create_clock -name $DATA_CLK_NAME \
             -period $CLK_PER \
             -waveform [list 0 [expr $CLK_PER / 2.0]] \
             $CLK_PORT_DATA

create_clock -name $WB_CLK_NAME \
             -period $CLK_PER \
             -waveform [list 0 [expr $CLK_PER / 2.0]] \
             $CLK_PORT_WB

# Group clocks together cleanly for uncertainty
set clk_list [get_clocks [list $DATA_CLK_NAME $WB_CLK_NAME]]

# Account for clock jitter and skew
set_clock_uncertainty -setup 0.2 $clk_list
set_clock_uncertainty -hold  0.1 $clk_list

####################################################################################
# 2. CLOCK DOMAIN CROSSING (CDC)
####################################################################################
# NOTE: If you use this asynchronous group, you MUST synthesize the RTL with 
# the parameter SYNCHRONOUS=0 so that the ASYNC_REG synchronizers are generated!
set_clock_groups -asynchronous -group [get_clocks $DATA_CLK_NAME] \
                               -group [get_clocks $WB_CLK_NAME]

####################################################################################
# 3. I/O DELAY CONSTRAINTS
####################################################################################
set data_inputs  [get_ports {i_ce i_trigger i_data}]
set wb_inputs    [get_ports {i_wb_cyc i_wb_stb i_wb_we i_wb_addr i_wb_data}]
set wb_outputs   [get_ports {o_wb_ack o_wb_stall o_wb_data o_interrupt}]

set IN_DELAY  [expr $CLK_PER * 0.2]
set OUT_DELAY [expr $CLK_PER * 0.3]

# Constrain Data Clock Domain I/O
set_input_delay -clock $DATA_CLK_NAME -max $IN_DELAY $data_inputs
set_input_delay -clock $DATA_CLK_NAME -min 0.0       $data_inputs

# Constrain Wishbone Clock Domain I/O
set_input_delay -clock $WB_CLK_NAME -max $IN_DELAY $wb_inputs
set_input_delay -clock $WB_CLK_NAME -min 0.0       $wb_inputs

set_output_delay -clock $WB_CLK_NAME -max $OUT_DELAY $wb_outputs
set_output_delay -clock $WB_CLK_NAME -min -0.5       $wb_outputs

####################################################################################
# 4. ENVIRONMENTAL CONSTRAINTS (Design Rule Checks - DRC)
####################################################################################
# To get realistic timing, we must model the physical environment of the chip/block.

# A. Output Loads: Assume outputs are driving a 10pF capacitive load
# (Adjust this value based on your specific standard cell library)
set_load 10.0 $wb_outputs

# B. Input Transitions: Model the fact that signals don't arrive with perfect square waves.
# We set a maximum transition time to prevent the tool from inserting weak buffers.
set_max_transition 0.5 [current_design]

# Alternatively, if you know the exact standard cell driving the inputs, you can use:
# set_driving_cell -lib_cell <your_buffer_name> -pin <pin_name> [all_inputs]

####################################################################################
# 5. VERIFICATION
####################################################################################
# Genus command to verify that all endpoints are successfully constrained
# This will catch any ports you may have missed.
check_timing_intent