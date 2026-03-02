module control_fsm (
  input  wire       clk_i,
  input  wire       rst_ni,
  input  wire [6:0] opcode_i,

  output reg        pc_write_o,
  output reg        ir_write_o,  // ir write enable, only high during fetch to capture instruction from memory
  output reg        reg_write_o,
  output reg        mem_write_o,
  output reg        adr_src_o,   // 0: PC, 1: ALU Result (for memory address)
     
  output wire [3:0] current_state_o //state output for debugging
);

  //state encoding
  localparam [3:0] FETCH      = 4'b0000,
                   DECODE     = 4'b0001,
                   EXEC_R     = 4'b0010, // R-Type (ADD, SUB)
                   EXEC_I     = 4'b0011, // I-Type (ADDI)
                   MEM_ADR    = 4'b0100, // Calculate memory address for Load/Store
                   MEM_RD     = 4'b0101, // Wait for Memory to Read
                   MEM_WB     = 4'b0110, // Writeback to Register File
                   MEM_WR     = 4'b0111, // Write to Memory
                   BRANCH     = 4'b1000, // Branch resolution
                   JUMP       = 4'b1001, // JAL
                   LUI_AUIPC  = 4'b1010, // LUI/AUIPC
                   JALR_ST    = 4'b1011, // JALR
                   FETCH_WAIT = 4'b1100;
    
  //opcode encodings, see control_unit for what each opcode is responsible for
  localparam [6:0] OP_R_TYPE = 7'b0110011, 
                   OP_I_TYPE = 7'b0010011, 
                   OP_LOAD   = 7'b0000011, 
                   OP_STORE  = 7'b0100011, 
                   OP_BRANCH = 7'b1100011, 
                   OP_JAL    = 7'b1101111, 
                   OP_JALR   = 7'b1100111,  
                   OP_LUI    = 7'b0110111, 
                   OP_AUIPC  = 7'b0010111, 
                   OP_FENCE  = 7'b0001111, 
                   OP_SYSTEM = 7'b1110011; 

  reg [3:0] state_q, state_d;
  assign current_state_o = state_q;

  //state register
  always @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) state_q <= FETCH;
    else         state_q <= state_d;
  end

  //next state logic
  always @(*) begin
    case (state_q)
      FETCH:      state_d = FETCH_WAIT; // wait one cycle to capture instruction from memory
      FETCH_WAIT: state_d = DECODE; 
      DECODE: begin
        case (opcode_i)
          OP_R_TYPE: state_d = EXEC_R;  // R-Type
          OP_I_TYPE: state_d = EXEC_I;  // I-Type
          OP_LOAD:   state_d = MEM_ADR; // Load (LB, LH, LW)
          OP_STORE:  state_d = MEM_ADR; // Store (SB, SW)
          OP_BRANCH: state_d = BRANCH;  // Branch
          OP_JAL:    state_d = JUMP;    // JAL
          OP_JALR:   state_d = JALR_ST; // JALR
          OP_LUI:    state_d = LUI_AUIPC; // LUI 
          OP_AUIPC:  state_d = LUI_AUIPC; // LUI/AUIPC
          default:   state_d = FETCH;   // Unknown Opcode
        endcase
      end
            
      EXEC_R, EXEC_I, LUI_AUIPC, MEM_RD:
        state_d = MEM_WB; 
            
      MEM_ADR: begin
        if (opcode_i == OP_LOAD)  state_d = MEM_RD; //load needs to wait
        else                      state_d = MEM_WR; //store writes immediately
      end
                        
      MEM_WB, MEM_WR, BRANCH, JUMP, JALR_ST:  
        state_d = FETCH;  //final states go back to fetch
            
      default: state_d = FETCH; 
    endcase
  end

  //control outputs
  always @(*) begin
    pc_write_o  = 1'b0;
    ir_write_o  = 1'b0;
    reg_write_o = 1'b0;
    mem_write_o = 1'b0;
    adr_src_o   = 1'b0; //default to pc

    case (state_q)
      FETCH: ; //the default 

      FETCH_WAIT: begin
        ir_write_o = 1'b1; //get instruction from memory
        pc_write_o = 1'b1; //advance the PC
      end

      MEM_RD: begin
        adr_src_o  = 1'b1; //use ALU result for memory address
      end
            
      MEM_WR: begin
        mem_write_o = 1'b1; //memory write for store instructions
        adr_src_o   = 1'b1; //use ALU result for memory address
      end
            
      MEM_WB: begin
        reg_write_o = 1'b1; //save the final result to the Register File
      end

      JUMP, JALR_ST: begin
        pc_write_o  = 1'b1; //update PC to jump target
        reg_write_o = 1'b1; //save return address in register
      end

      default: ;
            
    endcase
  end

endmodule