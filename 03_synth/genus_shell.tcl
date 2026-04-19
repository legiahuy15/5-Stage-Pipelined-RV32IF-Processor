
##################################################
#
#Khai Pham 
#HCMUT LAB 203 
#
##################################################
#file setup variables#
set top_module pipelined
##################################################
#Libraries setup#
#set_db library [list /opt/PDKs/skywater130/timing/sky130_fd_sc_hd__tt_025C_1v80.lib /opt/PDKs/sky130_sram_macros-dev/sky130_sram_1kbyte_1r1w_8x1024_8/sky130_sram_1kbyte_1r1w_8x1024_8_TT_1p8V_25C.lib ]
##################################################
#HDL files read#
read_hdl -sv -f 00_src/pipelined_list.f
##################################################
elaborate
set_top_module ${top_module}
write_hdl > 03_synth/${top_module}_elab.v
check_design -all
##################################################
#Timing constraint variables#
set FREQ_GHz 0.1
set FREQ [ expr ${FREQ_GHz}*1000000000.0 ]
set PERIOD [ expr (1.0/${FREQ})*1000000000000.0 ]
set IN_DLY [ expr $PERIOD/2.0 ]
set OUT_DLY [ expr $PERIOD/2.0 ]
##################################################
#set constraint for clock and input with output#
set clock [define_clock -period $PERIOD -name clk [clock_ports] ]
external_delay -clock clk -input $IN_DLY  -name delay_in [all_inputs]
external_delay -clock clk -output $OUT_DLY -name delay_out [all_outputs]

set fan_net_max 3
set_max_fanout ${fan_net_max} [get_design ${mod}]
set_max_fanout ${fan_net_max} [all_inputs]

##################################################
#Synthesize RTL code to generic#
syn_generic
write_hdl > 03_synth/${top_module}_generic.v
#Mapping technology to the generic#
syn_map
write_hdl > 03_synth/${top_module}_tech_map.v
#Optimizing the mapped technology netlist#
syn_opt  

report timing -lint
##################################################
#design post-synthesis export#
#Export the netlist 
write_hdl > 03_synth/${top_module}_gate.v
#Export the standard delay format of the synthesized design #
write_sdf -edges check_edge -setuphold "split" -recrem split > 03_synth/${top_module}.sdf

##################################################
#Reports export#
report timing -max_paths 10 > 04_reports/${top_module}.timing.rpt
report hierarchy > 04_reports/${top_module}.hier.rpt
report gates > 04_reports/${top_module}.gates.rpt
report datapath > 04_reports/${top_module}.datapath.rpt
report qor > 04_reports/${top_module}.qor.rpt
report area > 04_reports/${top_module}.area.rpt
report power > 04_reports/${top_module}.power.rpt

##################################################
#Open genus GUI 
gui_show