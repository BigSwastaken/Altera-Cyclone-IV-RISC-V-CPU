create_clock -name clk_i -period 20.000 [get_ports {clk_i}]
derive_clock_uncertainty
derive_pll_clocks