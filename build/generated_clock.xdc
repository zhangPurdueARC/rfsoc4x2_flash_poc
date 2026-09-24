create_clock -period 5.000 -name sys_clk_100m_p -waveform {0.000 2.5} [get_ports sys_clk_100m_p]
create_clock -period 5.000 -name sys_clk_100m_n -waveform {0.000 2.5} [get_ports sys_clk_100m_n]
