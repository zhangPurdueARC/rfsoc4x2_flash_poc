`timescale 1 ns / 1 ns
module test_tooling_tb;
    parameter PERIOD = 20;
    logic CLK = 1;
    always #(PERIOD/2) CLK++;

    integer x, y, z;
    test_tooling DUT(.CLK(CLK), .x(x), .y(y), .z(z));

    initial begin
        @(negedge CLK);
        x = 1;
        y = 1;
        @(posedge CLK);
        @(posedge CLK);
        @(negedge CLK);
        x = -1;
        y = -2;
        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);
        $finish;
    end

endmodule