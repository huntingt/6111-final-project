module Simple(
    input clock,
    input reset,
    input [31:0] a,
    input [31:0] b,
    output logic [31:0] result
    );
    
    always_ff @(posedge clock) begin
        if (reset) begin
            result <= 0;
        end else begin
            result <= a + b + 1;
        end
    end
endmodule
