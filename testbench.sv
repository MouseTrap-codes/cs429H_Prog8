`timescale 1ns/1ps

module tinker_core_tb;
    reg [31:0] instruction;

    // Instantiate the top-level module
    tinker_core uut (
        .instruction(instruction)
    );

    initial begin
        // Test 1: add rd, rs, rt
        // For "add" the opcode is 5'b11000.
        // Let's use: rd = 5, rs = 2, rt = 3; literal L = 0.
        instruction = {5'b11000, 5'b00101, 5'b00010, 5'b00011, 12'b0};
        #10;
        $display("Test ADD instruction = %h", instruction);
        #10;
        // Display register 5 (rd) in the ALU's regFile instance.
        $display("Register 5 after ADD = %h", uut.instruction_decoder.alu_inst_block.alu_inst.inst.registers[5]);

        // Test 2: sub rd, rs, rt
        // For "sub" the opcode is 5'b11010.
        // Let: rd = 6, rs = 7, rt = 8; L = 0.
        instruction = {5'b11010, 5'b00110, 5'b00111, 5'b01000, 12'b0};
        #10;
        $display("Test SUB instruction = %h", instruction);
        #10;
        $display("Register 6 after SUB = %h", uut.instruction_decoder.alu_inst_block.alu_inst.inst.registers[6]);

        // Test 3: mov rd, L
        // For "mov rd, L" the opcode is 5'b10010.
        // Let: rd = 7 and L = 12'hABC. (rs and rt are don't cares; set to 0)
        instruction = {5'b10010, 5'b00111, 5'b00000, 5'b00000, 12'hABC};
        #10;
        $display("Test MOV literal instruction = %h", instruction);
        #10;
        $display("Register 7 after MOV literal = %h", uut.instruction_decoder.alu_inst_block.alu_inst.inst.registers[7]);

        // Test 4: FPU addf rd, rs, rt
        // For "addf" the opcode is 5'b10100.
        // Let: rd = 8, rs = 9, rt = 10; L = 0.
        instruction = {5'b10100, 5'b01000, 5'b01001, 5'b01010, 12'b0};
        #10;
        $display("Test FPU ADDF instruction = %h", instruction);
        #10;
        $display("Register 8 after FPU ADDF = %h", uut.instruction_decoder.fpu_inst_block.fpu_inst.inst.registers[8]);

        #20;
        $finish;
    end

endmodule