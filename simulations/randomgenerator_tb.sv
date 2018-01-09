`timescale 1ns / 1ps

module randomgenerator_tb(

    );
    
    logic clk = 0;
    logic [3:0] out;
    
    always
        begin
            #1
            clk <= ~clk;
        end
    
    randomgenerator dut(clk, out);
    
endmodule
