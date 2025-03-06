module regFile (input[63:0] data, input we, input re1, input re2, input[4:0] rd, input[4:0] rs, input[4:0], rt, output[63:0] rsOut, output[63:0] rtOut);
    reg[63:0] registers[31:0];

    // read rs, rt
    always @(*) begin
        if (re1) begin
            rsOut = registers[rs];
        end
        if (re2) begin
            rtOut = registers[rt];
        end
    
    // write rd
    always @(*) begin
        if (re1) begin
            registers[rd] <= data;
        end
    
end_module;


module alu (input[4:0] opcode, input[4:0] rd, input[63:0] rs, input[63:0] rt, input[11:0] L);
    wire[63:0] result;

    always @(*) begin     // This is a combinational circuit
        case (opcode)
        // arithmetic
        5'b11000: result = rs + rt;  // add 
        5'b11010: result = rs + rt; // sub
        5'b11100: result = rs * rt; // mul
        5'b11101: result = rs / rt; // div
        // logical instructions
        5'b00000: result = rs & rt; // and
        5'b00001: result = rs | rt; // or
        5'b00010: result = rs ^ rt; // xor
        5'b00011: result = ~rs; // not
        5'b00100: result = rs >> rt; // shftr
        5'b00110: result = rs << rt; // shftl
        // data movement instructions
        5'b10001: result = rs; // mov rd, rs
        5'b10010: result[11:0] = L; // mov rd, L        
        endcase
    end

    regFile inst (result, 1, 0, 0, rd, rs, rt, 0, 0);
end_module

module fpu (input[4:0] opcode, input[4:0] rd, input[63:0] rs, input[63:0] rt, input[11:0] L);
    wire[63:0] result, op1, op2, data;
    assign op1 = $bitstoreal(rs);
    assign op2 = $bitstoreal(rt);

    always @(*) begin     // This is a combinational circuit
        case (opcode)
        // arithmetic
        5'b10100: result = rs + rt;  // addf
        5'b10101: result = rs + rt; // subf
        5'b10110: result = rs * rt; // mulf
        5'b10111: result = rs / rt; // divf
        endcase
    end

    assign data = $realtobits(result);
    regFile inst (data, 1, 0, 0, rd, rs, rt, 0, 0);
end_module

module instruction_decoder(input in);
    wire[4:0] opcode, rd, rs, rt;
    wire[11:0] L;

    // map instruction to its components
    assign opcode = in[31:27];
    assign rd = in[26:22];
    assign rs = in[21:17];
    assign rt = in[16:12];
    assign L = in[11:0];

    wire[63:0] rsO, rtO;
    regFile reg_file (0, 0, 1, 1, rd, rs, rt, rsO, rtO);

    // big switch statement to call either ALU or FPU
    always @(*) begin     // This is a combinational circuit
        case (opcode)
        // arithmetic
        5'b11000: alu(opcode, rd, rsO, rtO, L)  // add 
        5'b11010: alu(opcode, rd, rsO, rtO, L) // sub
        5'b11100: alu(opcode, rd, rsO, rtO, L) // mul
        5'b11101: alu(opcode, rd, rsO, rtO, L) // div
        // logical instructions
        5'b00000: alu(opcode, rd, rsO, rtO, L) // and
        5'b00001: alu(opcode, rd, rsO, rtO, L) // or
        5'b00010: alu(opcode, rd, rsO, rtO, L) // xor
        5'b00011: alu(opcode, rd, rsO, rtO, L) // not
        5'b00100: alu(opcode, rd, rsO, rtO, L) // shftr
        5'b00110: alu(opcode, rd, rsO, rtO, L) // shftl
        // data movement instructions
        5'b10001: alu(opcode, rd, rsO, rtO, L) // mov rd, rs
        5'b10010: alu(opcode, rd, rsO, rtO, L) // mov rd, L 
        5'b10100: fpu(opcode, rd, rsO, rtO, L)  // addf
        5'b10101: fpu(opcode, rd, rsO, rtO, L) // subf
        5'b10110: fpu(opcode, rd, rsO, rtO, L) // mulf
        5'b10111: fpu(opcode, rd, rsO, rtO, L) // divf       
        endcase
    end
end_module

module tinker_core(input[63:0] instruction);
    instruction_decoder inst (instruction);
end_module






