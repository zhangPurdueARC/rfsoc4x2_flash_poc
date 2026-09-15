# arguments
set output_dir ./build

if {[llength $argv] < 2} {
    puts "Usage: vivado -mode batch -source bitstream_project_gen.tcl -tclargs <design_top> <num_cpus> [timing] [clock_period_ns]"
    exit 1
}

set design_top [lindex $argv 0]
set num_cpus   [lindex $argv 1]

set do_timing 0
if {[llength $argv] > 2 && [lindex $argv 2] eq "timing"} {
    set do_timing 1
}

# Parse optional clock period argument
set clock_period ""
if {[llength $argv] > 3} {
    set clock_period [lindex $argv 3]
}

# new project
set proj_name $design_top
set proj_path "$output_dir/$proj_name.xpr"

if {[file exists $proj_path]} {
    puts "INFO: Opening existing project: $proj_path"
    open_project $proj_path
} else {
    puts "INFO: Creating new project: $proj_path"
    create_project $proj_name $output_dir -part xc7s50csga324-1 -force

    
    # get filelist
    set filelist_path "build/design.f"
    puts "INFO: Parsing filelist at '$filelist_path'..."

    if {![file exists $filelist_path]} {
        puts "ERROR: Filelist not found at '$filelist_path'. Please ensure it has been generated. Exiting."
        exit 1
    }

    set src_files [list]
    set base_dir [file dirname ./]

    # Read the file and process each line for source files
    set f_handle [open $filelist_path r]
    set f_content [read $f_handle]
    close $f_handle

    foreach line [split $f_content "\n"] {
        set line [string trim $line]

        if {$line == "" || [string match "#*" $line]} {
            continue
        }
        
        # Add any line that is not a comment to the source list
        set full_path [file join $base_dir $line]
        lappend src_files $full_path
    }

    if {[llength $src_files] > 0} {
        add_files -fileset sources_1 -norecurse $src_files
        puts "INFO: Added [llength $src_files] source files from filelist."
    }

    # Set the include directory directly as requested
    set_property include_dirs "./include" [get_filesets sources_1]
    puts "INFO: Set global include directory to './include'."

    # top
    if {($design_top in {"system_fpga" "system"})} {
        set mem_input "meminit.mem"
        if {![file exists $mem_input]} {
             puts "ERROR: $mem_input not found."
             exit 1
        }
        add_files $mem_input
    }
    
    if {$design_top != "system"} {
        add_files -fileset constrs_1 /home/ecegrid/a/ece437l/tools/vivado_extra/urbana.xdc
    }

    # IP
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

    # optional timing additions
    if {$do_timing} {
        set target_period 10.0
        if { $clock_period ne "" } {
            set target_period $clock_period
        }
        puts "INFO: The value of clock_period is: '$clock_period'"
        
        set half_period [expr {$target_period / 2.0}]
    
        set generated_xdc_path "$output_dir/generated_clock.xdc"
        puts "INFO: Generating clock constraint file: $generated_xdc_path with period ${target_period}ns."
        set f [open $generated_xdc_path "w"]

        # clock business
        set clk_port_name "CLK"
        if {[string match "*_fpga" $design_top]} {
            set clk_port_name "CLK_100MHZ"
        }
        puts $f "create_clock -period $target_period -name MAIN -waveform {0.000 $half_period} \[get_ports $clk_port_name\]"
        
        if {$design_top == "system_fpga"} {
            puts $f "create_generated_clock -name CPUCLK -source \[get_ports CLK_100MHZ\] -divide_by 2 \[get_nets SYS/CPUCLK\]"
            puts $f "\n# VIO debug path is not performance-critical, ignore it for timing analysis."
            puts $f "set_false_path -through \[get_nets {dbg_addr[*]}\]"
            puts $f "set_false_path -through \[get_nets {dbg_data_out[*]}\]"
        } elseif {$design_top == "system"} {
            puts $f "create_generated_clock -name CPUCLK -source \[get_ports CLK\] -divide_by 2 \[get_nets CPUCLK\]"
        }
    
        close $f
        add_files -fileset constrs_1 $generated_xdc_path
    }

    # Set properties
    set_property top $design_top [current_fileset]
    set_property verilog_define "USE_VIVADO" [current_fileset]
    
    # Check if we should enable the hardware memory load
    if {[string match "*_fpga" $design_top]} {
        set_property verilog_define "USE_VIVADO SYNTH_FPGA" [current_fileset]
        puts "INFO: SYNTH_FPGA defined. Memory will be initialized in bitstream (Slow Build)."
    } else {
        set_property verilog_define "USE_VIVADO" [current_fileset]
        puts "INFO: SYNTH_FPGA not defined. Memory will be empty (Fast Build)."
    }
}

# synthesis
if {$num_cpus > 8} {
  set max_threads 8
} else {
  set max_threads $num_cpus
}
set_param general.maxThreads $max_threads
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE "RuntimeOptimized" [get_runs synth_1]

reset_run synth_1
launch_runs synth_1 -j 32
wait_on_run synth_1

if {$design_top == "system_fpga"} {
    puts "INFO: Forcing debug hub clock connection..."
    open_run synth_1 -name synth_1
    
    set vio_clk_pin [get_pins -of_objects [get_cells vio_inst] -filter {NAME =~ *clk}]
    set vio_clk_net [get_nets -of_objects $vio_clk_pin]
    
    if { [llength $vio_clk_net] == 1 } {
        puts "INFO: Found VIO clock net: '$vio_clk_net'. Connecting to debug hub."
        connect_debug_port dbg_hub/clk $vio_clk_net
    } else {
        puts "ERROR: Could not find a unique clock net connected to vio_inst. Halting."
        exit 1
    }
}

if {$num_cpus > 8} {
  set max_threads 8
} else {
  set max_threads $num_cpus
}
set_param general.maxThreads $max_threads

# set_property STEPS.PLACE_DESIGN.ARGS.DIRECTIVE "RuntimeOptimized" [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.ARGS.DIRECTIVE "NoTimingRelaxation" [get_runs impl_1]
if {[string match "*_fpga" $design_top]} {
    launch_runs impl_1 -to_step write_bitstream -j 32
} else {
    launch_runs impl_1 -to_step route_design -j 32
}
wait_on_run impl_1

open_checkpoint $output_dir/$design_top.runs/impl_1/${design_top}_routed.dcp
write_verilog -force -mode funcsim "mapped/${design_top}.sv"
# write_mem_info -force $output_dir/$design_top.mmi
# reports

# fmax
if {$do_timing && ($design_top in {"system_fpga" "system"})} {
    puts "================================================================"
    puts "Calculating Maximum Frequency (Fmax) for each clock..."
    set all_clocks [get_clocks]

    foreach clock_name [get_property NAME $all_clocks] {
        set target_period [get_property PERIOD [get_clocks $clock_name]]
        set timing_paths [get_timing_paths -setup -nworst 1 -max_paths 1 -from [get_clocks $clock_name] -to [get_clocks $clock_name]]
        if {[llength $timing_paths] > 0} {
            set wns [get_property SLACK $timing_paths]
            set actual_period [expr {$target_period - $wns}]
            if {$actual_period > 0} {
                set fmax_mhz [expr {1000.0 / $actual_period}]
                set target_fmax_mhz [expr {1000.0 / $target_period}]
                if {$fmax_mhz > $target_fmax_mhz} {
                    puts [format "  - Clock: %-15s | Target: %7.2f MHz | Fmax: %7.2f MHz (%7.2f MHz)" $clock_name $target_fmax_mhz $target_fmax_mhz $fmax_mhz]
                } else {
                    puts [format "  - Clock: %-15s | Target: %7.2f MHz | Fmax: %7.2f MHz" $clock_name $target_fmax_mhz $fmax_mhz]
                }
            } else {
                puts "  - Clock: $clock_name -> Path failed too severely to calculate a realistic Fmax."
            }
        } else {
            puts "  - Clock: $clock_name -> No intra-clock paths found to analyze for Fmax."
        }
    }     
    puts "================================================================"
    if {$design_top == "system"} {
    # define the clock crossings
        set crossing_pairs [list \
            {CPUCLK MAIN} \
            {MAIN CPUCLK} \
        ]

        foreach pair $crossing_pairs {
            set from_clk [lindex $pair 0]
            set to_clk [lindex $pair 1]

            set timing_paths [get_timing_paths -setup -nworst 1 -max_paths 1 -from [get_clocks $from_clk] -to [get_clocks $to_clk]]

            if {[llength $timing_paths] > 0} {
                set wns [get_property SLACK $timing_paths]
                set requirement [get_property REQUIREMENT $timing_paths]
                set corrected_wns [expr {$wns + $requirement}]
                set actual_delay [expr {$requirement - $wns}]
                set effective_fmax 0
                if {$actual_delay > 0} {
                    set effective_fmax [expr {1000.0 / $actual_delay}]
                }
                puts [format "  - Path: %-8s -> %-8s | WNS: %8.3fns | Effective Freq: %7.2f MHz" $from_clk $to_clk $corrected_wns $effective_fmax]    
            } else {
                puts "  - Path: $from_clk -> $to_clk | No timed paths found."
            }
        }
        puts "================================================================"
    }
}

report_utilization -file $output_dir/utilization.rpt
report_timing_summary -file $output_dir/timing.rpt
report_timing -nworst 10 -file $output_dir/worst_timing_paths.rpt
