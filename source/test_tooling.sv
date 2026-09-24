module test_tooling (
    input logic CLK, 
    input integer x, y,
    output integer z
);
    integer interior_x, interior_y; // purely to make synthesis timing work
    always_ff @(posedge CLK) begin
        interior_x <= x;
        interior_y <= y;
    end

    always_ff @(posedge CLK) begin
        z <= interior_x >> interior_y;
    end
endmodule