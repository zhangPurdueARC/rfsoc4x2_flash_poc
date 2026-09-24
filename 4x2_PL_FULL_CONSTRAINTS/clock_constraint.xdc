# copied from https://github.com/sebajor/rfsoc4x2/blob/main/adc_test/clocks.xdc
# clk is added by bitstream gen... don't worry about it too much - will appear under build/generated_clock.xdc
set_property IOSTANDARD LVDS [get_ports sys_clk_100m_p]
set_property PACKAGE_PIN AM15 [ get_ports sys_clk_100m_p]
set_property IOSTANDARD LVDS [get_ports sys_clk_100m_n]
set_property PACKAGE_PIN AN15 [ get_ports sys_clk_100m_n]