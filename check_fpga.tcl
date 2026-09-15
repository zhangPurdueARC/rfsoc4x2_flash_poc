open_hw_manager
connect_hw_server
open_hw_target

set device [lindex [get_hw_devices xczu48dr*] 0]
if {$device eq ""} {
    puts "ERROR: No hardware device matching 'xczu48dr*' found."
    exit 1
}

close_hw_manager