module control_unit (
  //inputs from instruction
  input  wire [6:0] opcode_i,
  input  wire [2:0] funct3_i,
  input  wire       funct7_5_i,         //modifier bit
  input  wire       less_than_i,        //from ALU (for BLT/BGE)
  input  wire       unsigned_less_than_i, //from ALU (for BLTU/BGEU)
  input  wire       zero_i,             //from ALU (for BEQ/BNE)

  //control signals 
  output wire       pc_src_o,           //0: PC+4(next line), 1: PC+Imm(jump)
  output reg  [1:0] result_src_o,       //0: ALU Result, 1: Memory Data, 2: PC+4
  output reg        alu_src_b_o,        //0: register B, 1: use immediate
  output reg        alu_src_a_o,        //0: register A, 1: PC
  output reg  [2:0] imm_src_o,          //000: I-Type, 001: S-Type, 010: B-Type, 011: J-Type, 100: U-Type
  output reg  [3:0] alu_control_o       //controls ALU operation
);

  //opcode encodings
  localparam [6:0] OP_R_TYPE = 7'b0110011, // ADD, SUB, XOR, etc.
                   OP_I_TYPE = 7'b0010011, // ADDI, XORI, etc.
                   OP_LOAD   = 7'b0000011, // LW, LB, LH, etc.
                   OP_STORE  = 7'b0100011, // SW, SB, SH, etc.
                   OP_BRANCH = 7'b1100011, // BEQ, BNE, BLT, BGE, BLTU, BGEU
                   OP_JAL    = 7'b1101111, 
                   OP_JALR   = 7'b1100111, 
                   OP_LUI    = 7'b0110111, 
                   OP_AUIPC  = 7'b0010111, 
                   OP_FENCE  = 7'b0001111, //memory barrier, not implemented
                   OP_SYSTEM = 7'b1110011; //ECALL, EBREAK, not implemented

  reg branch, branch_condition, jump;

  //main decoder
  always @(*) begin
    branch       = 0;
    jump         = 0;
    result_src_o = 2'b00; // default to ALU result
    alu_src_b_o  = 0;
    alu_src_a_o  = 0;
    imm_src_o    = 3'b000; // default to I-Type

    case (opcode_i)
      OP_R_TYPE: ;//default control signals are correct for R-Type

      OP_I_TYPE: 
        alu_src_b_o  = 1; //use immediate for ALU input        

      OP_LOAD: begin
        alu_src_b_o  = 1; // Address = Reg + Imm
        result_src_o = 2'b01; // Save memory result, not ALU result
      end

      OP_STORE: begin
        alu_src_b_o  = 1; // Address = Reg + Imm
        imm_src_o    = 3'b001; // S-Type 
      end

      OP_BRANCH: begin
        branch    = 1;
        imm_src_o = 3'b010; // B-Type
      end

      OP_JAL: begin
        jump         = 1; 
        imm_src_o    = 3'b011; // J-Type  
        result_src_o = 2'b10; // PC+4
      end

      OP_JALR: begin 
        jump         = 1; 
        alu_src_b_o  = 1; 
        result_src_o = 2'b10; 
      end

      OP_LUI:  begin 
        alu_src_b_o  = 1; 
        imm_src_o    = 3'b100; // U-Type
      end 

      OP_AUIPC:  begin 
        alu_src_b_o  = 1; 
        alu_src_a_o  = 1; // Use PC as SrcA in ALU
        imm_src_o    = 3'b100; // U-Type
      end 

      OP_FENCE: ; //not implemented in this project
      OP_SYSTEM: ; //not implemented in this project

      default: ; // for unkown opcodes, treat as NOP 

    endcase
  end

  //alu decoder
  always @(*) begin
    alu_control_o = 4'b0000; //default to ADD 

    case (opcode_i)
      OP_R_TYPE: begin
        case (funct3_i)
          3'b000:  alu_control_o = (funct7_5_i) ? 4'b1000 : 4'b0000; // SUB : ADD
          3'b001:  alu_control_o = 4'b0001; // SLL
          3'b010:  alu_control_o = 4'b0010; // SLT
          3'b011:  alu_control_o = 4'b0011; // SLTU
          3'b100:  alu_control_o = 4'b0100; // XOR
          3'b101:  alu_control_o = (funct7_5_i) ? 4'b1101 : 4'b0101; // SRA : SRL
          3'b110:  alu_control_o = 4'b0110; // OR
          3'b111:  alu_control_o = 4'b0111; // AND
          default: ;
        endcase
      end
      OP_I_TYPE: begin
        case (funct3_i)
          3'b010:  alu_control_o = 4'b0010; // SLTI
          3'b011:  alu_control_o = 4'b0011; // SLTIU
          3'b100:  alu_control_o = 4'b0100; // XORI
          3'b110:  alu_control_o = 4'b0110; // ORI
          3'b111:  alu_control_o = 4'b0111; // ANDI
          default: ;
        endcase
      end
      OP_BRANCH: alu_control_o = 4'b1000; //SUB for comparison
      OP_LUI:    alu_control_o = 4'b1010; //LUI ( pass immediate through)
      default: ;
    endcase
  end

  //branch condition logic
  always @(*) begin
    case (funct3_i)
      3'b000:  branch_condition = zero_i;  // BEQ
      3'b001:  branch_condition = ~zero_i; // BNE
      3'b100:  branch_condition = less_than_i; // BLT
      3'b101:  branch_condition = ~less_than_i; // BGE
      3'b110:  branch_condition = unsigned_less_than_i; // BLTU
      3'b111:  branch_condition = ~unsigned_less_than_i; // BGEU
      default: branch_condition = 0; // default to not taken for unknown funct3
    endcase
  end

  assign pc_src_o = jump | (branch & branch_condition); //always take jump, take branch if condition is met

endmodule