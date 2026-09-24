// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Thu Sep 24 14:03:26 2026
// Host        : ececomp2.ecn.purdue.edu running 64-bit Oracle Linux Server release 8.10
// Command     : write_verilog -force -mode funcsim mapped/flash_test_fpga.sv
// Design      : flash_test_fpga
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xczu48dr-ffvg1517-2-e
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* ECO_CHECKSUM = "ca6593e" *) 
(* NotValidForBitStream *)
module flash_test_fpga
   (sys_clk_100m_p,
    sys_clk_100m_n,
    PB_0,
    PB_1,
    PB_4,
    SW_0,
    SW_1,
    R_LED_0,
    R_LED_1,
    B_LED_0,
    B_LED_1,
    W_LED_0,
    W_LED_1,
    W_LED_2);
  input sys_clk_100m_p;
  input sys_clk_100m_n;
  input PB_0;
  input PB_1;
  input PB_4;
  input SW_0;
  input SW_1;
  output R_LED_0;
  output R_LED_1;
  output B_LED_0;
  output B_LED_1;
  output W_LED_0;
  output W_LED_1;
  output W_LED_2;

  wire B_LED_0;
  wire B_LED_0_OBUF;
  wire B_LED_1;
  wire B_LED_1_OBUF;
  wire PB_0;
  wire PB_0_IBUF;
  wire PB_1;
  wire PB_1_IBUF;
  wire PB_4;
  wire PB_4_IBUF;
  wire R_LED_0;
  wire R_LED_0_OBUF;
  wire R_LED_1;
  wire R_LED_1_OBUF;
  wire SW_0;
  wire SW_0_IBUF;
  wire SW_1;
  wire SW_1_IBUF;
  wire W_LED_0;
  wire W_LED_0_OBUF;
  wire W_LED_1;
  wire W_LED_1_OBUF;
  wire W_LED_2;
  wire W_LED_2_OBUF;
  wire [2:0]result;
  wire sys_clk;
  (* IBUF_LOW_PWR *) wire sys_clk_100m_n;
  (* IBUF_LOW_PWR *) wire sys_clk_100m_p;
  (* MAX_PROG_DELAY = "0" *) wire sys_clk_BUFG;
  wire val1;
  wire \val1_reg_n_0_[0] ;
  wire \val1_reg_n_0_[1] ;
  wire val2;
  wire \val2_reg_n_0_[0] ;
  wire \val2_reg_n_0_[1] ;

  OBUF B_LED_0_OBUF_inst
       (.I(B_LED_0_OBUF),
        .O(B_LED_0));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    B_LED_0_reg
       (.C(sys_clk_BUFG),
        .CE(1'b1),
        .CLR(PB_4_IBUF),
        .D(\val2_reg_n_0_[0] ),
        .Q(B_LED_0_OBUF));
  OBUF B_LED_1_OBUF_inst
       (.I(B_LED_1_OBUF),
        .O(B_LED_1));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    B_LED_1_reg
       (.C(sys_clk_BUFG),
        .CE(1'b1),
        .CLR(PB_4_IBUF),
        .D(\val2_reg_n_0_[1] ),
        .Q(B_LED_1_OBUF));
  IBUF PB_0_IBUF_inst
       (.I(PB_0),
        .O(PB_0_IBUF));
  IBUF PB_1_IBUF_inst
       (.I(PB_1),
        .O(PB_1_IBUF));
  IBUF PB_4_IBUF_inst
       (.I(PB_4),
        .O(PB_4_IBUF));
  OBUF R_LED_0_OBUF_inst
       (.I(R_LED_0_OBUF),
        .O(R_LED_0));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    R_LED_0_reg
       (.C(sys_clk_BUFG),
        .CE(1'b1),
        .CLR(PB_4_IBUF),
        .D(\val1_reg_n_0_[0] ),
        .Q(R_LED_0_OBUF));
  OBUF R_LED_1_OBUF_inst
       (.I(R_LED_1_OBUF),
        .O(R_LED_1));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    R_LED_1_reg
       (.C(sys_clk_BUFG),
        .CE(1'b1),
        .CLR(PB_4_IBUF),
        .D(\val1_reg_n_0_[1] ),
        .Q(R_LED_1_OBUF));
  IBUF SW_0_IBUF_inst
       (.I(SW_0),
        .O(SW_0_IBUF));
  IBUF SW_1_IBUF_inst
       (.I(SW_1),
        .O(SW_1_IBUF));
  OBUF W_LED_0_OBUF_inst
       (.I(W_LED_0_OBUF),
        .O(W_LED_0));
  LUT2 #(
    .INIT(4'h6)) 
    W_LED_0_i_1
       (.I0(\val1_reg_n_0_[0] ),
        .I1(\val2_reg_n_0_[0] ),
        .O(result[0]));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    W_LED_0_reg
       (.C(sys_clk_BUFG),
        .CE(1'b1),
        .CLR(PB_4_IBUF),
        .D(result[0]),
        .Q(W_LED_0_OBUF));
  OBUF W_LED_1_OBUF_inst
       (.I(W_LED_1_OBUF),
        .O(W_LED_1));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT4 #(
    .INIT(16'h8778)) 
    W_LED_1_i_1
       (.I0(\val2_reg_n_0_[0] ),
        .I1(\val1_reg_n_0_[0] ),
        .I2(\val1_reg_n_0_[1] ),
        .I3(\val2_reg_n_0_[1] ),
        .O(result[1]));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    W_LED_1_reg
       (.C(sys_clk_BUFG),
        .CE(1'b1),
        .CLR(PB_4_IBUF),
        .D(result[1]),
        .Q(W_LED_1_OBUF));
  OBUF W_LED_2_OBUF_inst
       (.I(W_LED_2_OBUF),
        .O(W_LED_2));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT4 #(
    .INIT(16'hF880)) 
    W_LED_2_i_1
       (.I0(\val2_reg_n_0_[0] ),
        .I1(\val1_reg_n_0_[0] ),
        .I2(\val1_reg_n_0_[1] ),
        .I3(\val2_reg_n_0_[1] ),
        .O(result[2]));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    W_LED_2_reg
       (.C(sys_clk_BUFG),
        .CE(1'b1),
        .CLR(PB_4_IBUF),
        .D(result[2]),
        .Q(W_LED_2_OBUF));
  (* BOX_TYPE = "PRIMITIVE" *) 
  (* CAPACITANCE = "DONT_CARE" *) 
  (* IBUF_DELAY_VALUE = "0" *) 
  (* IFD_DELAY_VALUE = "AUTO" *) 
  IBUFDS #(
    .CCIO_EN_M("TRUE"),
    .CCIO_EN_S("TRUE"),
    .DIFF_TERM("FALSE"),
    .IOSTANDARD("DEFAULT")) 
    ibufds_inst
       (.I(sys_clk_100m_p),
        .IB(sys_clk_100m_n),
        .O(sys_clk));
  (* XILINX_LEGACY_PRIM = "BUFG" *) 
  (* XILINX_TRANSFORM_PINMAP = "VCC:CE" *) 
  BUFGCE #(
    .CE_TYPE("ASYNC"),
    .SIM_DEVICE("ULTRASCALE_PLUS")) 
    sys_clk_BUFG_inst
       (.CE(1'b1),
        .I(sys_clk),
        .O(sys_clk_BUFG));
  LUT2 #(
    .INIT(4'h8)) 
    \val1[1]_i_1 
       (.I0(PB_1_IBUF),
        .I1(PB_0_IBUF),
        .O(val1));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    \val1_reg[0] 
       (.C(sys_clk_BUFG),
        .CE(val1),
        .CLR(PB_4_IBUF),
        .D(SW_0_IBUF),
        .Q(\val1_reg_n_0_[0] ));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    \val1_reg[1] 
       (.C(sys_clk_BUFG),
        .CE(val1),
        .CLR(PB_4_IBUF),
        .D(SW_1_IBUF),
        .Q(\val1_reg_n_0_[1] ));
  LUT2 #(
    .INIT(4'h2)) 
    \val2[1]_i_1 
       (.I0(PB_1_IBUF),
        .I1(PB_0_IBUF),
        .O(val2));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    \val2_reg[0] 
       (.C(sys_clk_BUFG),
        .CE(val2),
        .CLR(PB_4_IBUF),
        .D(SW_0_IBUF),
        .Q(\val2_reg_n_0_[0] ));
  (* OPT_MODIFIED = "RETARGET" *) 
  FDCE #(
    .IS_CLR_INVERTED(1'b1)) 
    \val2_reg[1] 
       (.C(sys_clk_BUFG),
        .CE(val2),
        .CLR(PB_4_IBUF),
        .D(SW_1_IBUF),
        .Q(\val2_reg_n_0_[1] ));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
