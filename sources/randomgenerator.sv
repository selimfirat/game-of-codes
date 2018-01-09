module randomgenerator(
    input logic clk,
    output logic[3:0] out
    );
    
    logic [15:0] seq = 16'b0;
    
    always_ff @(posedge clk)
        begin
         /*   if (reset)
                seq <= 4'b0000;
            else*/
            seq <= { seq[14:0], ~(seq[15] ^ seq[14] ^ seq[13])};
        end
    
    assign out = seq[3:0];
    
endmodule
