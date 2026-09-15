module test_tooling (
    input logic CLK, 
    input integer x, y,
    output integer z
);
    always_ff @(posedge CLK) begin
        z <= x + y;
    end
endmodule