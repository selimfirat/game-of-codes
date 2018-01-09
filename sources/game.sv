
module game(
    input logic clk,
	// for 7 segment display
	output a, b, c, d, e, f, g, dp, 
    output [3:0] an,
	
	// for 4x4 keypad
	output [3:0] keyb_row,
	input  [3:0] keyb_col,
	
    // for step motor 
    output [3:0] phases,
    
    input game_mode,
    input reset
    );
    
    //matrix keypad scanner
    logic [3:0] key_value;
    keypad4X4 keypad4X4_inst0(
        .clk(clk),
        .keyb_row(keyb_row), // just connect them to FPGA pins, row scanner
        .keyb_col(keyb_col), // just connect them to FPGA pins, column scanner
        .key_value(key_value), //user's output code for detected pressed key: row[1:0]_col[1:0]
        .key_valid(key_valid)  // user's output valid: if the key is pressed long enough (more than 20~40 ms), key_valid becomes '1' for just one clock cycle.
    );    
    
    logic [3:0] rnd;
    randomgenerator rnd_instance(clk, rnd);
        
    logic [3:0] in0; //initial value
    logic [3:0] in1 = 4'h0; //initial value
    logic [3:0] in2 = 4'h0; //initial value
    logic [3:0] in3 = 4'h0; //initial value
    
    
    SevSeg_4digit SevSeg_4digit_inst0(
        .clk(clk),
        .in3(in3), .in2(in2), .in1(in1), .in0(in0), //user inputs for each digit (hexadecimal)
        .a(a), .b(b), .c(c), .d(d), .e(e), .f(f), .g(g), .dp(dp), // just connect them to FPGA pins (individual LEDs).
        .an(an)   // just connect them to FPGA pins (enable vector for 4 digits active low) 
    );
    
    logic [1:0] direction;
    logic [1:0] rotation_duration;
   
    
    logic start = 0;
    
    logic [3:0] cur = 4'h0;
    logic wait_key = 0;
    logic [3:0] score = 4'h0;
    logic score_given = 1;
    
    logic start_motor = 0;

    assign in0 = score;
    logic new_round = 1;
    logic [3:0] expected_key ;
    
    assign direction = cur[1:0];
    assign rotation_duration = cur[3:2];
            // 1'b0: left  1'b1: right    
            // 1'b0: short  1'b1: long
            // duration_direction
    
    always@ (posedge clk)
    begin

        case (cur)
            4'b00_00: expected_key <= 4'b11_11;
            4'b00_01: expected_key <= 4'b00_00;
            4'b00_10: expected_key <= 4'b00_01;
            4'b00_11: expected_key <= 4'b00_10;
            4'b01_00: expected_key <= 4'b00_11;
            4'b01_01: expected_key <= 4'b01_00;
            4'b01_10: expected_key <= 4'b01_01;
            4'b01_11: expected_key <= 4'b01_10;
            4'b10_00: expected_key <= 4'b01_11;
            4'b10_01: expected_key <= 4'b10_00;
            4'b10_10: expected_key <= 4'b10_01;
            4'b10_11: expected_key <= 4'b10_10;
            4'b11_00: expected_key <= 4'b10_11;
            4'b11_01: expected_key <= 4'b11_00;
            4'b11_10: expected_key <= 4'b11_01;
            4'b11_11: expected_key <= 4'b11_10;
        endcase
            
        if (start == 1)
            start <= 0;
            
        if (start_motor == 1) begin
                start <= 1;
                
                start_motor <= 0;
        end
        
        // training
        if (game_mode == 1) begin
            score <= 4'h0;
            if (key_valid == 1'b1 && start_motor == 0) begin
                cur <= key_value + 4'd1;
                start_motor <= 1;
            end
        end
        
        if (reset == 1)
            score <= 0;
        
        // game
        if (game_mode == 0) begin
            if (new_round == 1 && start_motor == 0 && score_given == 1) begin
                cur <= rnd;
                start_motor <= 1;
                score_given <= 0;
             end
        
            if (key_valid == 1'b1 && score_given == 0) begin
                if (key_value == expected_key && score != 4'h9)
                    score <= score + 4'd1;
                
                if (key_value != expected_key && score != 4'h0)
                    score <= score - 4'd1;
                
                score_given <= 1;
                new_round <= 1;
            end
         end
     end
    
    
    steppermotor_wrapper steppermotor_wrapper_inst0(
        
        .clk(clk), //100Mhz on Basys3
        
        //user input for motor rotation direction. 
        // direction[0]: first movement 
        // direction[1]: second movement
        // 1'b0: left  1'b1: right	
        .direction(direction), 
        
        //user input for motor rotation duration.
        // rotation_duration[0]: first movement 
        // rotation_duration[1]: second movement
        // 1'b0: short  1'b1: long
        .rotation_duration(rotation_duration), 
        
        // just connect them to FPGA (motor driver)	
        .phases(phases), 
        
        //user input to initiate motor. a pulse (at least one clock cycle) start motor movements. 
        // if you re-apply it before the motor finishes both movements, it is ignored.
        .start(start) 
    );

endmodule