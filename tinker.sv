//---------------------------------------------------------------------
// regFile Module
//---------------------------------------------------------------------
module regFile (
    input  [63:0] data,      // Data to be written
    input         we,        // Write enable signal
    input         re1,       // Read enable for rs
    input         re2,       // Read enable for rt
    input  [4:0]  rd,        // Write address
    input  [4:0]  rs,        // Read address 1
    input  [4:0]  rt,        // Read address 2
    output reg [63:0] rsOut, // Data output from address rs
    output reg [63:0] rtOut  // Data output from address rt
);
    reg [63:0] registers [31:0];

    // read rs, rt (combinational read)
    always @(*) begin
        if (re1)
            rsOut = registers[rs];
        else
            rsOut = 64'b0;
        if (re2)
            rtOut = registers[rt];
        else
            rtOut = 64'b0;
    end

    // write rd (combinational write for this stage)
    always @(*) begin
        if (we)
            registers[rd] = data;
    end
endmodule

//---------------------------------------------------------------------
// ALU Module
//---------------------------------------------------------------------
module alu (
    input  [4:0]  opcode,
    input  [4:0]  rd,         // destination register
    input  [63:0] rs,         // operand 1
    input  [63:0] rt,         // operand 2
    input  [11:0] L,          // literal value (for mov)
    output reg [63:0] result  // ALU result
);
    always @(*) begin // combinational logic
        case (opcode)
            // arithmetic
            5'b11000: result = rs + rt;         // add
            5'b11010: result = rs - rt;         // sub 
            5'b11100: result = rs * rt;         // mul
            5'b11101: result = rs / rt;         // div
            // logical instructions
            5'b00000: result = rs & rt;         // and
            5'b00001: result = rs | rt;         // or
            5'b00010: result = rs ^ rt;         // xor
            5'b00011: result = ~rs;             // not (ignores rt)
            // shift instructions (using rt as shift amount)
            5'b00100: result = rs >> rt;        // shftr
            5'b00110: result = rs << rt;        // shftl
            // data movement instructions
            5'b10001: result = rs;              // mov rd, rs
            5'b10010: begin                     // mov rd, L
                        result = 64'b0;
                        result[11:0] = L;    // literal into bits 11:0
                     end
            default: result = 64'b0;
        endcase
    end

    // Instantiate a regFile for write-back (for demonstration)
    regFile inst (result, 1'b1, 1'b0, 1'b0, rd, rs, rt, 64'b0, 64'b0);
endmodule

//---------------------------------------------------------------------
// FPU Module
//---------------------------------------------------------------------
module fpu (
    input  [4:0]  opcode,
    input  [4:0]  rd,         // destination (passed for regFile instantiation)
    input  [63:0] rs,         // operand 1 (bit pattern)
    input  [63:0] rt,         // operand 2 (bit pattern)
    input  [11:0] L,          // literal (if needed)
    output reg [63:0] result  // FPU result (as 64-bit)
);
    real op1, op2, res_real;
    always @(*) begin // combinational logic
        op1 = $bitstoreal(rs);
        op2 = $bitstoreal(rt);
        case (opcode)
            5'b10100: res_real = op1 + op2; // addf
            5'b10101: res_real = op1 - op2; // subf
            5'b10110: res_real = op1 * op2; // mulf
            5'b10111: res_real = op1 / op2; // divf
            default: res_real = 0.0;
        endcase
        result = $realtobits(res_real);
    end

    // Instantiate a regFile for write-back (for demonstration)
    regFile inst (result, 1'b1, 1'b0, 1'b0, rd, rs, rt, 64'b0, 64'b0);
endmodule

//---------------------------------------------------------------------
// Instruction Decoder Module
//---------------------------------------------------------------------
module instruction_decoder(
    input [31:0] in  // 32-bit instruction
);
    wire [4:0] opcode, rd, rs, rt;
    wire [11:0] L;

    // map instruction to its components (bit positions per spec)
    assign opcode = in[31:27];
    assign rd     = in[26:22];
    assign rs     = in[21:17];
    assign rt     = in[16:12];
    assign L      = in[11:0];

    wire [63:0] rsO, rtO;
    // Instantiate a register file for reading; no write occurs here.
    regFile reg_file (64'b0, 1'b0, 1'b1, 1'b1, rd, rs, rt, rsO, rtO);

    // Instantiate both ALU and FPU modules
    wire [63:0] alu_result;
    alu alu_inst (opcode, rd, rsO, rtO, L, alu_result);
    wire [63:0] fpu_result;
    fpu fpu_inst (opcode, rd, rsO, rtO, L, fpu_result);

    // big switch statement to select between ALU and FPU results
    // (Floating-point opcodes: 10100, 10101, 10110, 10111; others use ALU)
    reg [63:0] final_result;
    always @(*) begin     // This is a combinational circuit
        case (opcode)
            // arithmetic
            5'b11000: final_result = alu_result;  // add 
            5'b11010: final_result = alu_result;  // sub
            5'b11100: final_result = alu_result;  // mul
            5'b11101: final_result = alu_result;  // div
            // logical instructions
            5'b00000: final_result = alu_result;  // and
            5'b00001: final_result = alu_result;  // or
            5'b00010: final_result = alu_result;  // xor
            5'b00011: final_result = alu_result;  // not
            5'b00100: final_result = alu_result;  // shftr
            5'b00110: final_result = alu_result;  // shftl
            // data movement instructions
            5'b10001: final_result = alu_result;  // mov rd, rs
            5'b10010: final_result = alu_result;  // mov rd, L 
            // floating-point instructions
            5'b10100: final_result = fpu_result;   // addf
            5'b10101: final_result = fpu_result;   // subf
            5'b10110: final_result = fpu_result;   // mulf
            5'b10111: final_result = fpu_result;   // divf
            default: final_result = 64'b0;
        endcase
    end

    // (Optional) You can instantiate a write-back register file here to store final_result.
endmodule

//---------------------------------------------------------------------
// tinker_core Module
//---------------------------------------------------------------------
module tinker_core(
    input [31:0] instruction  // 32-bit instruction input
);
    instruction_decoder inst (instruction);
endmodule
