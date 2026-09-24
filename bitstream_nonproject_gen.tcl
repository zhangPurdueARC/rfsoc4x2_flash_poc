# --- DEBUG FLAG ---
set enable_debug 0

# --- Debug Print Procedure ---
proc print_debug {msg} {
    global enable_debug
    if {$enable_debug} { puts "DEBUG: $msg" }
}

# --- SCRIPT START ---
# 1. Argument and Path Setup
# ----------------------------
set output_dir ./build
file mkdir $output_dir

if {[llength $argv] < 2} {
    puts "Usage: vivado -mode batch -source <script_name>.tcl -tclargs <design_top> <num_cpus> \[timing] \[clock_period]"
    exit 1
}
set design_top   [lindex $argv 0]
set num_cpus     [lindex $argv 1]
set do_timing    0
if {[llength $argv] > 2 && [lindex $argv 2] eq "timing"} { set do_timing 1 }
set clock_period ""
if {[llength $argv] > 3} { set clock_period [lindex $argv 3] }

set main_part "xczu48dr-ffvg1517-2-e"
if {$num_cpus > 8} { set max_threads 8 } else { set max_threads $num_cpus }
set base_dir [file normalize [file dirname ./]]

set_param general.maxThreads $max_threads

puts "INFO: Starting non-project flow for top-level: '$design_top' on part '$main_part' with $max_threads threads."

# 2. Collect Source Files
# -----------------------
set filelist_path "build/design.f"
if {![file exists $filelist_path]} { puts "ERROR: Filelist not found at '$filelist_path'."; exit 1 }
set f_handle [open $filelist_path r]; set f_content [read $f_handle]; close $f_handle
set main_sources [list]; set main_xdc_files [list]
foreach line [split $f_content "\n"] {
    set line [string trim $line]
    if {$line == "" || [string match "#*" $line]} { continue }
    set full_path [file normalize [file join $base_dir $line]]
    lappend main_sources $full_path
}

# 3. Constraint & Configuration Handling
# --------------------------------------
if {[string match "*_fpga" $design_top]} { lappend main_xdc_files "4x2_PL_FULL_CONSTRAINTS/4x2_1PPS.xdc"  "4x2_PL_FULL_CONSTRAINTS/4x2_LED_PB__SW.xdc"  "4x2_PL_FULL_CONSTRAINTS/4x2_PL_DDR4.xdc"  "4x2_PL_FULL_CONSTRAINTS/4x2_PMOD.xdc"  "4x2_PL_FULL_CONSTRAINTS/4x2_QSFP.xdc"  "4x2_PL_FULL_CONSTRAINTS/4x2_SYZYGY.xdc"}
if {$do_timing} {
    set generated_xdc_path "$output_dir/generated_clock.xdc"; puts "INFO: Generating clock constraint file: $generated_xdc_path"
    set f [open $generated_xdc_path "w"]
    set target_period 10.0; if { $clock_period ne "" } { set target_period $clock_period }
    set half_period [expr {$target_period / 2.0}]; set clk_port_name "CLK"
    if {[string match "*_fpga" $design_top]} { set clk_port_name "CLK_FPGA" }
    puts $f "create_clock -period $target_period -name MAIN -waveform {0.000 $half_period} \[get_ports $clk_port_name\]"
    if {$design_top == "system_fpga"} { puts $f "create_generated_clock -name CPUCLK -source \[get_ports CLK_FPGA\] -divide_by 2 \[get_nets SYS/CPUCLK\]"
    } elseif {$design_top == "system"} { puts $f "create_generated_clock -name CPUCLK -source \[get_ports CLK\] -divide_by 2 \[get_nets CPUCLK\]" }
    close $f; lappend main_xdc_files $generated_xdc_path
}

# 4. Determine which steps to run
# -------------------------------
set synth_dcp_file "$output_dir/${design_top}_synthesized.dcp"
set impl_dcp_file "$output_dir/${design_top}_routed.dcp"
set mem_file "meminit.hex"

set run_main_synth 0
set run_impl 0

# Check if synthesis is required
set sources_are_newer 0
if {![file exists $synth_dcp_file]} {
    puts "INFO: Main synthesis checkpoint not found. Synthesis is required."
    set run_main_synth 1
} else {
    foreach src $main_sources {
        if {[file mtime $src] > [file mtime $synth_dcp_file]} {
            puts "INFO: Source file '[file tail $src]' is newer than the synthesis checkpoint."
            set sources_are_newer 1
            break
        }
    }
    if {$sources_are_newer} {
        puts "INFO: One or more source files are newer. Re-running main synthesis."
        set run_main_synth 1
    }
}

# Check if implementation is required
if {$run_main_synth} {
    set run_impl 1
} elseif {![file exists $impl_dcp_file]} {
    puts "INFO: Final implementation checkpoint not found. Implementation is required."
    set run_impl 1
} elseif {[file exists $mem_file] && [file mtime $mem_file] > [file mtime $impl_dcp_file]} {
    puts "INFO: Memory initialization file is newer than the final implementation. Re-running implementation only."
    set run_impl 1
}

if {!$run_main_synth && !$run_impl} {
    puts "INFO: All outputs are up-to-date. Skipping flow. Generating reports."
}

# 6. Add Debug IP (VIO)
# ---------------------
if {$design_top == "system_fpga"} {
    puts "INFO: Creating and configuring VIO IP for memory debug..."
    create_ip -name vio -vendor xilinx.com -library ip -module_name mem_debug_vio
    
    set_property -dict [list \
        CONFIG.C_NUM_PROBE_IN {1} \
        CONFIG.C_PROBE_IN0_WIDTH {32} \
        CONFIG.C_NUM_PROBE_OUT {1} \
        CONFIG.C_PROBE_OUT0_WIDTH {14} \
    ] [get_ips mem_debug_vio]
    
    puts "INFO: Generating IP target files..."
    generate_target all [get_ips mem_debug_vio]
    
    puts "INFO: Launching out-of-context synthesis for the VIO IP..."
    create_ip_run [get_ips mem_debug_vio]
    launch_runs [get_runs mem_debug_vio_synth_1] -j 32
    wait_on_run [get_runs mem_debug_vio_synth_1]
    
    puts "INFO: VIO IP created and synthesized successfully."
}

# 6. Main Synthesis and Implementation Flow
# -------------------------------------------
if {$run_main_synth || $run_impl} {    
    if {!$run_main_synth && $run_impl} {
        puts "INFO: Skipping synthesis. Opening existing synthesized checkpoint."
        open_checkpoint $synth_dcp_file
        puts "INFO: Reading design constraints..."
        foreach xdc $main_xdc_files { read_xdc $xdc }
    } else {
        puts "INFO: Reading main design sources (including RAM)..."
        read_verilog -sv $main_sources
        puts "INFO: Reading design constraints..."; foreach xdc $main_xdc_files { read_xdc $xdc }
    }

    if {$run_main_synth} {
        puts "INFO: Starting main synthesis..."
        if {[string match "*_fpga" $design_top]}  {
            synth_design -top $design_top -part $main_part -directive RuntimeOptimized \
                -verilog_define {USE_VIVADO VIVADO_MAPPED SYNTH_FPGA} -include_dirs "./include"
        }
        synth_design -top $design_top -part $main_part -directive RuntimeOptimized \
            -verilog_define {USE_VIVADO VIVADO_MAPPED} -include_dirs "./include"
        write_checkpoint -force $synth_dcp_file
    }
    
    if {$run_impl} {
        puts "INFO: Starting implementation..."
        if {![string match "*_fpga" $design_top]} {
            set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
            set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
        }
        opt_design
        place_design
        route_design -directive NoTimingRelaxation
        write_checkpoint -force $impl_dcp_file; puts "INFO: Implementation checkpoint written to '$impl_dcp_file'."
        write_verilog -force -mode funcsim "mapped/${design_top}.sv"

        if {[string match "*_fpga" $design_top]} { 
            puts "INFO: Writing bitstream..."; write_bitstream -force $output_dir/$design_top.bit
            # puts "INFO: Writing memory map info..."; write_mem_info -force $output_dir/$design_top.mmi
        }
    }
}

# 7. Reports
# ------------
if {[file exists $impl_dcp_file]} {
    puts "INFO: Opening final checkpoint to generate reports."; open_checkpoint $impl_dcp_file
    if {$do_timing} {
        puts "================================================================"; puts "Calculating Maximum Frequency (Fmax) for each clock..."
        set all_clocks [get_clocks]
        foreach clock_name [get_property NAME $all_clocks] {
            if {[llength [get_clocks $clock_name]] > 0} {
                set target_period [get_property PERIOD [get_clocks $clock_name]]
                set timing_paths [get_timing_paths -setup -nworst 1 -max_paths 1 -from [get_clocks $clock_name] -to [get_clocks $clock_name]]
                if {[llength $timing_paths] > 0} {
                    set wns [get_property SLACK $timing_paths]; set actual_period [expr {$target_period - $wns}]
                    if {$actual_period > 0} {
                        set fmax_mhz [expr {1000.0 / $actual_period}]; set target_fmax_mhz [expr {1000.0 / $target_period}]
                        puts [format "  - Clock: %-15s | Target: %7.2f MHz | Fmax: %7.2f MHz" $clock_name $target_fmax_mhz $fmax_mhz]
                    } else { puts "  - Clock: $clock_name -> Path failed timing too severely to calculate Fmax." }
                } else { puts "  - Clock: $clock_name -> No intra-clock paths found." }
            }
        }
        puts "================================================================"
    }
    report_utilization -file $output_dir/utilization.rpt; report_timing_summary -file $output_dir/timing.rpt
    puts "INFO: Reports generated in '$output_dir'."
} else { puts "WARNING: Final checkpoint not found. Cannot generate reports." }

puts "INFO: Script finished successfully."