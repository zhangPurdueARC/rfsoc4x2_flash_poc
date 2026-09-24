// see constraints files - will define useful ports (manual management is required)

// this is a simple unsigned adder as a proof of concept for FPGA work
module flash_test_fpga (
    input logic sys_clk_100m_p, // CLK synth is weird... 
    input logic sys_clk_100m_n, // due to RFSoC 4x2 largely supporting 
    input logic PB_0, // acts as select for write
    input logic PB_1, // acts as update signal
    input logic PB_4, // acts as nRST 
    input logic SW_0, // set bit zero
    input logic SW_1, // set bit one
    output logic R_LED_0, // input 0 bit zero
    output logic R_LED_1, // input 0 bit one
    output logic B_LED_0, // input 1 bit zero
    output logic B_LED_1, // input 1 bit one
    output logic W_LED_0, // output bit zero
    output logic W_LED_1, // output bit one
    output logic W_LED_2  // output bit two
);
    IBUFDS ibufds_inst (
        .I(sys_clk_100m_p),   // Connects to external positive pin
        .IB(sys_clk_100m_n),  // Connects to external negative pin
        .O(sys_clk)  // This is your single-ended internal clock wire
    );

    logic unsigned [1:0] val1, val2;

    always_ff @(posedge sys_clk, negedge PB_4) begin
        if (!PB_4) begin
            val1 <= 0;
            val2 <= 0;
        end
        else if (PB_1) begin
           if (PB_0) val1 <= {SW_1, SW_0};
           else      val2 <= {SW_1, SW_0};
        end
    end 

    logic unsigned [2:0] result;
    assign result = val1 + val2;

    always_ff @(posedge sys_clk, negedge PB_4) begin
        if (!PB_4) begin
            R_LED_0 <= 0;
            R_LED_1 <= 0;
            B_LED_0 <= 0;
            B_LED_1 <= 0;
            W_LED_0 <= 0;
            W_LED_1 <= 0;
            W_LED_2 <= 0;
        end
        else begin
            R_LED_0 <= val1[0];
            R_LED_1 <= val1[1];
            B_LED_0 <= val2[0];
            B_LED_1 <= val2[1];
            W_LED_0 <= result[0];
            W_LED_1 <= result[1];
            W_LED_2 <= result[2];
        end
    end
    
endmodule